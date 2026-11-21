#!/usr/bin/env python3
"""Stages pull requests that are labeled for testing and keeps a status comment
on each of them.

Pull requests with the label of a staging branch are squash merged on top of
`develop`, in order of pull request number. Pull requests that share commits
with another labeled pull request, for example because one was merged into the
other to resolve a conflict between them, are merged with a merge commit
instead so that the shared history lets the resolution apply. Pull requests
that do not merge cleanly are left out.

Only approved commits are staged. Adding the label approves the commit that the
pull request is at in that moment. Later commits of authors without write
access are approved by ticking the checkbox in the status comment.

The status comment of each pull request shows three things:

- the deployment: what is live, or why the last deployment failed
- the queue: when the next deployment is and which commit it will include
- the actionable items: approvals and merge conflicts, with a checkmark when
  there is nothing to do

All state lives in hidden metadata of the status comment. After the label is
removed or the pull request is merged, the comment shows the periods that each
commit was deployed.

Usage (the configuration is read from ../staging-labels.json):

    staging.py stage  <staging branch> [--push]
        Merge the labeled pull requests on top of the current commit, move HEAD
        to the result and optionally force push it to the staging branch.
    staging.py check  <staging branch>
        Merge in memory only and refresh the status comments.
    staging.py record <staging branch>
        Record what the triggering event changed: a label that was added or
        removed, a pull request that was closed, or a ticked approval checkbox.
    staging.py deploy <staging branch> --result success|tests|failed
                      [--staging SHA] [--deployed SHA] [--previous SHA] [--manual-by LOGIN]
        Record the outcome of a deployment, then check.
    staging.py labels
        Create the configured labels that do not exist yet.
    staging.py matrix
        Print the configuration of the staging branches that the triggering
        event concerns, as JSON for a workflow matrix.

Requires git 2.38 or later, a full clone and `gh` authenticated through
GH_TOKEN. Comments are only written when running in GitHub Actions, locally
they are printed instead.
"""

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path
from urllib.parse import quote

CONFIG_PATH = Path(__file__).resolve().parents[1] / "staging-labels.json"
SNIPPET_VERIFY = Path(__file__).resolve().parents[1] / "bash" / "changelog-verify.sh"
SNIPPET_GUIDE = "https://faforever.github.io/fa/development/changelog#format-of-a-snippet"
WORKFLOWS_PATH = Path(__file__).resolve().parents[2]
CRON_RE = re.compile(r"""^\s*-\s*cron:\s*["']?([^"'\n#]+)""", re.M)
BOT = os.environ.get("STAGING_BOT", "github-actions[bot]")
REPO = os.environ.get("GITHUB_REPOSITORY", "FAForever/fa")
REPO_URL = f"{os.environ.get('GITHUB_SERVER_URL', 'https://github.com')}/{REPO}"
RUN_URL = f"{REPO_URL}/actions/runs/{os.environ.get('GITHUB_RUN_ID', '0')}"
LIVE = os.environ.get("GITHUB_ACTIONS") == "true"

MAX_CONFLICT_LINES = 30
MAX_LINE_LENGTH = 160

DATA_RE = re.compile(r"<!-- staging-data: (\{.*?\}) -->", re.S)
STAGED_RE = re.compile(r"^Staged from \S+/pull/(\d+) at ([0-9a-f]{40})$", re.M)
CHECKED_RE = re.compile(r"^- \[[xX]\] Approve \[`[0-9a-f]+`\]\(\S+/pull/\d+/commits/([0-9a-f]{40})\)", re.M)
CONFLICT_INFO_RE = re.compile(r"^(\d{6}) ([0-9a-f]{40}) ([123])\t(.*)$")
ANNOTATION_RE = re.compile(r"^::(?:error|warning|notice)[^:]*::")

LEFT_OUT_REASONS = {
    "conflict": "merge conflict",
    "unapproved": "no approved commit",
    "missing": "the approved commit no longer exists",
    "snippet": "invalid changelog snippet",
}

#region Time


def parse_time(text):
    return datetime.fromisoformat(text.replace("Z", "+00:00"))


def iso(t):
    return t.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


_now = None


def now():
    """The time of this run, fixed so that all comments agree"""
    global _now
    if _now is None:
        override = os.environ.get("STAGING_NOW")
        _now = parse_time(override) if override else datetime.now(timezone.utc).replace(microsecond=0)
    return _now


def next_cron(expr, after):
    """The next time after `after` that matches a cron expression of the form
    `minute hour day-of-month month day-of-week` with numbers or `*`"""
    minute, hour, dom, month, dow = expr.split()
    day = after.date()
    for _ in range(400):
        if ((dom == "*" or int(dom) == day.day)
                and (month == "*" or int(month) == day.month)
                and (dow == "*" or int(dow) % 7 == day.isoweekday() % 7)):
            t = datetime(day.year, day.month, day.day, int(hour), int(minute), tzinfo=timezone.utc)
            if t > after:
                return t
        day += timedelta(days=1)
    raise ValueError(f"No time matches {expr}")


def static_time(t):
    t = parse_time(t) if isinstance(t, str) else t
    return f"{t:%a} {t.day} {t:%b %Y %H:%M} UTC"


def relative_time(t):
    """Rendered by GitHub as for example 'in 6 days' or '2 hours ago', with the
    full time on hover. GitHub only keeps the datetime attribute"""
    t = parse_time(t) if isinstance(t, str) else t
    return f'<relative-time datetime="{iso(t)}">{t:%a} {t.day} {t:%b %H:%M} UTC</relative-time>'


def plural(count, word):
    return f"{count} {word}{'' if count == 1 else 's'}"


def duration(seconds):
    days = int(seconds // 86400)
    if seconds < 3600:
        return plural(max(1, int(seconds // 60)), "minute")
    if days == 0:
        return plural(int(seconds // 3600), "hour")
    weeks, days = divmod(days, 7)
    parts = ([plural(weeks, "week")] if weeks else []) + ([plural(days, "day")] if days else [])
    return " and ".join(parts)


#endregion

#region Git and GitHub


def git(*args, ok=(0,), stdin=None):
    result = subprocess.run(["git", *args], capture_output=True, text=True, encoding="utf-8",
                            errors="replace", input=stdin)
    if result.returncode not in ok:
        raise RuntimeError(f"git {' '.join(args)} failed ({result.returncode}): {result.stderr.strip()}")
    return result


def git_out(*args):
    return git(*args).stdout.strip()


def commit_available(sha):
    if git("cat-file", "-e", f"{sha}^{{commit}}", ok=(0, 1, 128)).returncode == 0:
        return True
    return git("fetch", "--quiet", "origin", sha, ok=(0, 1, 128)).returncode == 0


def count_commits(old, new):
    return int(git_out("rev-list", "--count", f"{old}..{new}"))


def is_ancestor(old, new):
    return git("merge-base", "--is-ancestor", old, new, ok=(0, 1)).returncode == 0


class GitHub:
    """Thin wrapper around `gh` so that tests can replace it"""

    def __init__(self):
        self._access = {}

    def _run(self, args, body=None):
        result = subprocess.run(["gh", *args], capture_output=True, text=True, encoding="utf-8",
                                input=json.dumps(body) if body is not None else None)
        if result.returncode != 0:
            raise RuntimeError(f"gh {' '.join(args)} failed: {result.stderr.strip()}")
        return json.loads(result.stdout) if result.stdout.strip() else None

    def api(self, path, method="GET", body=None):
        args = ["api", "-X", method, path] + (["--input", "-"] if body is not None else [])
        return self._run(args, body)

    def list_prs(self, label):
        # All pages, so that no labeled pull request is silently left out
        pages = self._run(["api", "--paginate", "--slurp", f"repos/{REPO}/pulls?state=open&base=develop&per_page=100"])
        prs = [p for page in pages for p in page if label in [lbl["name"] for lbl in p["labels"]]]
        return sorted(({"number": p["number"], "author": p["user"]["login"], "title": p["title"],
                        "head": p["head"]["sha"]} for p in prs), key=lambda p: p["number"])

    def comments(self, pr):
        pages = self._run(["api", "--paginate", "--slurp", f"repos/{REPO}/issues/{pr}/comments"])
        return [comment for page in pages for comment in page]

    def get_comment(self, comment_id):
        """The comment, or None when it was deleted. Other errors are raised so
        that a temporary failure does not create a second status comment"""
        try:
            return self.api(f"repos/{REPO}/issues/comments/{comment_id}")
        except RuntimeError as error:
            if "HTTP 404" in str(error):
                return None
            raise

    def pr_labels(self, pr):
        return [label["name"] for label in self.api(f"repos/{REPO}/issues/{pr}/labels")]

    def create_comment(self, pr, body):
        return self.api(f"repos/{REPO}/issues/{pr}/comments", "POST", {"body": body})

    def edit_comment(self, comment_id, body):
        return self.api(f"repos/{REPO}/issues/comments/{comment_id}", "PATCH", {"body": body})

    def delete_comment(self, comment_id):
        self.api(f"repos/{REPO}/issues/comments/{comment_id}", "DELETE")

    def remove_label(self, pr, label):
        self.api(f"repos/{REPO}/issues/{pr}/labels/{quote(label)}", "DELETE")

    def write_access(self, user):
        if user not in self._access:
            try:
                permission = self.api(f"repos/{REPO}/collaborators/{user}/permission")["permission"]
            except RuntimeError:
                permission = "none"
            self._access[user] = permission in ("admin", "maintain", "write")
        return self._access[user]

    def labels(self):
        return [label["name"] for label in self._run(["label", "list", "--repo", REPO, "--limit", "500", "--json", "name"])]

    def create_label(self, name, color, description):
        try:
            self._run(["label", "create", name, "--repo", REPO, "--color", color, "--description", description])
        except RuntimeError as error:
            # Another job may have created it in the meantime
            if "already exists" not in str(error):
                raise


#endregion

#region Status comment


def encode(data):
    # A double dash would end the HTML comment, JSON can escape it
    return json.dumps(data, separators=(",", ":"), sort_keys=True).replace("--", "-\\u002d")


class Status:
    """The status comment of one pull request for one staging branch"""

    def __init__(self, gh, cfg, pr, author=None):
        self.gh, self.cfg, self.pr, self.author = gh, cfg, pr, author
        self.marker = f"<!-- staging-status: {cfg['branch']} -->"
        self.id, self.body, self.url, self.data = None, "", None, {}
        self.stale = []

    def _read(self, comment):
        self.id, self.body, self.url = comment["id"], comment["body"], comment["html_url"]
        match = DATA_RE.search(self.body)
        self.data = json.loads(match.group(1)) if match else {}

    def load(self):
        # The newest comment is the current one. Older ones remain when deleting
        # them failed after a repost, they are deleted on the next save
        found = [c for c in self.gh.comments(self.pr) if c["user"]["login"] == BOT and self.marker in c["body"]]
        if found:
            self._read(max(found, key=lambda c: c["id"]))
            self.stale = [c["id"] for c in found if c["id"] != self.id]
        return self

    def _delete_stale(self):
        for comment_id in self.stale:
            try:
                self.gh.delete_comment(comment_id)
            except RuntimeError as error:
                print(f"Could not delete the outdated status comment {comment_id}: {error}")
        self.stale = []

    def save(self, updates, notify=None):
        """Merges the updates into the metadata, which is read again first so
        that fields written by a parallel run are kept, and writes the comment.

        `notify` is (key, users, reason). It deletes and reposts the comment to
        mention the users, once per key. Returns the URL of the comment."""
        if self.id and LIVE:
            fresh = self.gh.get_comment(self.id)
            if fresh:
                self._read(fresh)
            else:
                # Another run reposted it in the meantime, continue from that one
                self.id, self.data = None, {}
                self.load()

        self.data.update(updates)
        mention = ""
        if notify and notify[0] != self.data.get("notified"):
            key, users, reason = notify
            self.data["notified"] = key
            users = sorted({u for u in users if u and u != BOT and not u.endswith("[bot]")})
            mentions = " ".join("@" + u for u in users)
            mention = f"\n\n🔔 {mentions}: {reason}" if users else f"\n\n🔔 {reason}"
        else:
            notify = None

        body = f"{self.marker}\n<!-- staging-data: {encode(self.data)} -->\n{render(self)}{mention}\n"

        if not LIVE:
            print(f"--- Status comment of #{self.pr}{' (reposted)' if notify else ''} ---\n{body}", file=sys.stderr)
            return f"{REPO_URL}/pull/{self.pr}"

        if self.id and not notify:
            if body != self.body:
                self._read(self.gh.edit_comment(self.id, body))
        else:
            # The old comment is only deleted once its replacement exists, so
            # that a failed request never loses the approval and the history
            if self.id:
                self.stale.append(self.id)
            self._read(self.gh.create_comment(self.pr, body))
        self._delete_stale()
        return self.url


def pr_link(pr):
    # GitHub adds a cross-reference to the timeline of the other pull request
    # for #123 and for plain links, but not for links through redirect.github.com
    return f"[#{pr}](https://redirect.github.com/{REPO}/pull/{pr})"


def pr_commit(pr, sha):
    return f"[`{sha[:7]}`]({REPO_URL}/pull/{pr}/commits/{sha})"


def deploy_commit(sha):
    return f"[`{sha[:7]}`]({REPO_URL}/commit/{sha})"


def render(status):
    data, name, pr = status.data, status.cfg["name"], status.pr
    deployed = data.get("deployed")
    if not data.get("labeled") and not deployed:
        return render_history(status)

    lines = []
    failed, left_out = data.get("failed"), data.get("left_out")
    live = f" · {pr_commit(pr, deployed['sha'])} from {relative_time(deployed['at'])} is still live" if deployed else ""
    if failed:
        lines.append(f"❌ Deploying to {name} failed {relative_time(failed['at'])}: {failed['reason']} ([run]({failed['run']})){live}")
    elif left_out:
        lines.append(f"❌ Left out of the {name} deployment {relative_time(left_out['at'])}: {left_out['reason']}")
    elif deployed:
        by = f" manually by {deployed['by']}" if deployed.get("by") else ""
        since = f" · first deployed {relative_time(deployed['since'])}" if deployed["since"] != deployed["at"] else ""
        lines.append(f"✅ Deployed{by} to {name} {relative_time(deployed['at'])} with "
                     f"{pr_commit(pr, deployed['sha'])} as {deploy_commit(deployed['deploy_sha'])}{since}")
    else:
        lines.append(f"🌐 Not yet deployed to {name}")

    next_deploy = relative_time(next_cron(status.cfg["deploy_cron"], now()))
    check = data.get("check") or {}
    state = check.get("state")
    if not data.get("labeled"):
        removed = data.get("removed") or {}
        why = "Closed" if data.get("final") == "closed" else f"Removed from staging{' by ' + removed['by'] if removed.get('by') else ''}"
        lines.append(f"🕒 {why}, no longer deployed after {next_deploy}")
    elif state in LEFT_OUT_REASONS:
        lines.append(f"❌ Not in the deployment {next_deploy}: {LEFT_OUT_REASONS[state]}")
    elif state == "clean":
        delta = f" ({check['delta']})" if check.get("delta") else ""
        lines.append(f"🕒 Deploys {next_deploy} with {pr_commit(pr, check['sha'])}{delta}")
    else:
        lines.append(f"🕒 Deploys {next_deploy}")

    text = "\\\n".join(lines)
    if not data.get("labeled"):
        return text
    if data.get("checking"):
        return f"{text}\n\n⏳ Checking for merge conflicts…"

    items = []
    if check.get("approve"):
        items.append(f"- [ ] Approve {pr_commit(pr, check['approve'])} for staging ({check['approve_note']})")
    conflict = check.get("conflict")
    if conflict:
        cause = "`develop`" if conflict["cause"] == "develop" else ", ".join(pr_link(p) for p in conflict["cause"])
        items.append(f"- Resolve the merge conflict with {cause} before the next deployment, otherwise this pull request is left out of it")
    if check.get("snippets"):
        report = "; ".join(f"`{line}`" for line in check["snippets"][:3])
        items.append(f"- Fix the [changelog snippet]({SNIPPET_GUIDE}) before the next deployment, otherwise this pull "
                     f"request is left out of it. The changelog check reports: {report}")
    for other in check.get("conflicted_by", []):
        items.append(f"- {pr_link(other)} conflicts with this pull request and is left out until it is resolved there")

    if not items:
        return f"{text}\n\n✅ No action needed"
    text += "\n\n⚠️ Action needed:\n\n" + "\n".join(items)
    if conflict:
        text += "\n\n" + render_conflict(status.cfg, conflict)
    return text


def render_conflict(cfg, conflict):
    if conflict["cause"] == "develop":
        commands = "git fetch origin develop\ngit merge origin/develop"
        advice = "Merge `develop` into this pull request and resolve the conflicts."
    else:
        commands = "\n".join(f"git fetch origin pull/{p}/head\ngit merge FETCH_HEAD" for p in conflict["cause"])
        advice = ("Merge the other pull request into this one and resolve the conflicts, or remove the label from one of them. "
                  "Pull requests that share commits are staged with a merge commit so that the resolution applies.")
    return (f"Red is what is staged before this pull request, green is this pull request:\n\n{conflict['lines']}\n\n"
            f"<details><summary>How to resolve</summary>\n\n{advice} Changes are picked up until the next stage run "
            f"{relative_time(next_cron(cfg['stage_cron'], now()))}.\n\n```sh\n{commands}\n# resolve the conflicts, commit and push\n```\n\n</details>")


def render_history(status):
    data, name, pr = status.data, status.cfg["name"], status.pr
    if data.get("final") == "merged":
        end = "merged into `develop`"
    elif data.get("final") == "closed":
        end = "closed"
    else:
        removed = data.get("removed") or {}
        end = f"removed from staging{' by ' + removed['by'] if removed.get('by') else ''}"

    history = data.get("history", [])
    if not history:
        return f"🧪 Not deployed to {name} before this pull request was {end}"

    total = sum((parse_time(p["to"]) - parse_time(p["from"])).total_seconds() for p in history)
    lines = [f"🧪 Tested in {name} for {duration(total)} before this pull request was {end}", ""]
    for period in history:
        seconds = (parse_time(period["to"]) - parse_time(period["from"])).total_seconds()
        lines.append(f"- {pr_commit(pr, period['sha'])} from {static_time(period['from'])} "
                     f"to {static_time(period['to'])} ({duration(seconds)})")
    return "\n".join(lines)


def close_period(data, until):
    """Moves the current deployment into the history"""
    deployed = data.get("deployed")
    history = list(data.get("history", []))
    if deployed:
        history.append({"sha": deployed["sha"], "from": deployed["since"], "to": until})
    return {"deployed": None, "history": history}


#endregion

#region Merging


def merge(ours, theirs):
    """Merges without a working tree. Returns the tree and, when it conflicts,
    the conflicting files as {path: {stage: blob}}"""
    result = git("merge-tree", "--write-tree", "--no-messages", ours, theirs, ok=(0, 1))
    lines = result.stdout.splitlines()
    if result.returncode == 0:
        return lines[0], None
    files = {}
    for line in lines[1:]:
        match = CONFLICT_INFO_RE.match(line)
        if match:
            files.setdefault(match[4], {})[int(match[3])] = match[2]
    return lines[0], files


def blob(sha):
    return subprocess.run(["git", "cat-file", "blob", sha], capture_output=True).stdout


def conflict_lines(files):
    """Only the conflicting lines, without context or headers, as one diff
    block per file"""
    out, used, hidden = [], 0, 0
    for path, stages in sorted(files.items()):
        if 2 not in stages or 3 not in stages:
            what = ("deleted before this pull request, which changes it" if 2 not in stages
                    else "changed before this pull request, which deletes it")
            out.append(f"`{path}`: {what}")
            continue

        contents = [blob(stages[k]) if k in stages else b"" for k in (2, 1, 3)]
        if any(b"\0" in c for c in contents):
            out.append(f"`{path}`: binary file")
            continue

        with tempfile.TemporaryDirectory() as tmp:
            paths = []
            for name, content in zip(("ours", "base", "theirs"), contents):
                paths.append(os.path.join(tmp, name))
                Path(paths[-1]).write_bytes(content)
            merged = git("merge-file", "-p", "-L", "staged", "-L", "base", "-L", "pr", *paths, ok=range(0, 128)).stdout

        hunks, hunk, side = [], [], None
        for line in merged.splitlines():
            line = line.rstrip("\r")
            if line.startswith("<<<<<<< staged"):
                side, hunk = "-", []
            elif line == "=======" and side == "-":
                side = "+"
            elif line.startswith(">>>>>>> pr") and side == "+":
                hunks.append(hunk)
                side = None
            elif side:
                hunk.append(side + (line if len(line) <= MAX_LINE_LENGTH else line[:MAX_LINE_LENGTH] + "…"))

        shown = []
        for hunk in hunks:
            if used + len(hunk) > MAX_CONFLICT_LINES:
                hidden += len(hunk)
                continue
            if shown:
                shown.append("")
            shown += hunk
            used += len(hunk)
        if shown:
            fence = "````" if any("```" in line for line in shown) else "```"
            out.append(f"`{path}`\n{fence}diff\n" + "\n".join(shown) + f"\n{fence}")
        elif hunks:
            out.append(f"`{path}`")
    if hidden:
        out.append(f"{plural(hidden, 'more conflicting line')} not shown")
    return "\n\n".join(out) if out else "The conflicting files could not be determined"


def snippet_errors(tree, before):
    """Runs changelog-verify.sh the way the changelog workflow does, in
    changelog/snippets, on the changelog files that a merge adds or changes
    between two trees. Files that were already there are left out, so that an
    invalid snippet on develop neither hides nor blames a pull request. The
    files are written without touching the working tree and only read by the
    script from develop. Returns what the script complains about, or None when
    it passes"""
    changed = [path for path in git("diff", "-z", "--name-only", "--no-renames", "--diff-filter=AM",
                                    before, tree, "--", "changelog").stdout.split("\0") if path]
    if not changed:
        return None
    with tempfile.TemporaryDirectory() as tmp:
        for entry in filter(None, git("ls-tree", "-r", "-z", tree, "--", *changed).stdout.split("\0")):
            meta, path = entry.split("\t", 1)
            mode, kind, sha = meta.split()
            # The changelog workflow can not run when the folders themselves
            # are replaced, for example by a link
            if path in ("changelog", "changelog/snippets"):
                return [f"{path} must be a folder"]
            target = Path(tmp, path)
            target.parent.mkdir(parents=True, exist_ok=True)
            # Links and submodules are written as empty files, so that the
            # script still checks their names without following them
            regular = kind == "blob" and mode in ("100644", "100755")
            target.write_bytes(blob(sha) if regular else b"")
        snippets = Path(tmp, "changelog", "snippets")
        snippets.mkdir(parents=True, exist_ok=True)
        result = subprocess.run(["bash", str(SNIPPET_VERIFY)], cwd=snippets, capture_output=True,
                                text=True, encoding="utf-8", errors="replace")
    if result.returncode == 0:
        return None
    # Annotations of the script are reduced to their message
    lines = [ANNOTATION_RE.sub("", line.strip()) for line in (result.stdout + result.stderr).splitlines()
             if line.strip() and not line.strip().startswith("- Verified")]
    return lines or [f"{SNIPPET_VERIFY.name} failed"]


def staged_prs(sha, skip_top=False):
    """{pull request: commit} of the staging commits at the tip of the first
    parent history of a commit. `skip_top` skips the commits that a deployment
    adds on top of the staging branch"""
    found, skipped = {}, 0
    log = git_out("log", "--first-parent", "-n", "300", "--format=%B%x1e", sha)
    for message in log.split("\x1e"):
        match = STAGED_RE.search(message)
        if match:
            found.setdefault(int(match[1]), match[2])
        elif found or not skip_top or skipped >= 5:
            break
        else:
            skipped += 1
    return found


#endregion

#region Commands


def load_event():
    path = os.environ.get("GITHUB_EVENT_PATH")
    event = json.loads(Path(path).read_text(encoding="utf-8")) if path and Path(path).exists() else {}
    return os.environ.get("GITHUB_EVENT_NAME", ""), event


def relevant(cfg, name, event):
    """Whether an event concerns the label of this staging branch"""
    if name == "pull_request_target":
        if (event.get("label") or {}).get("name") == cfg["label"]:
            return True
        return cfg["label"] in [label["name"] for label in event["pull_request"]["labels"]]
    if name == "issue_comment":
        return f"<!-- staging-status: {cfg['branch']} -->" in event["comment"]["body"]
    return True


def record(gh, cfg, name, event):
    """Records what an event changed, before the check runs"""
    if not relevant(cfg, name, event):
        return
    label, t = cfg["label"], iso(now())

    if name == "issue_comment":
        comment, sender = event["comment"], event["sender"]["login"]
        if comment["user"]["login"] != BOT or sender == BOT or "pull_request" not in event["issue"]:
            return
        old = (event.get("changes") or {}).get("body", {}).get("from", "")
        ticked = set(CHECKED_RE.findall(comment["body"])) - set(CHECKED_RE.findall(old))
        if not ticked:
            return
        status = Status(gh, cfg, event["issue"]["number"], event["issue"]["user"]["login"]).load()
        offered = (status.data.get("check") or {}).get("approve")
        if offered in ticked and gh.write_access(sender):
            status.save({"approved": {"sha": offered, "by": sender, "at": t}, "checking": True})
        else:
            # Writing the comment again clears the checkbox
            print(f"{sender} can not approve {', '.join(ticked)}: no write access or not the commit that is offered")
            status.save({})
        return

    if name != "pull_request_target":
        return
    pr, action, sender = event["pull_request"], event["action"], event["sender"]["login"]
    labels = [label["name"] for label in pr["labels"]]
    status = Status(gh, cfg, pr["number"], pr["user"]["login"]).load()
    approver = (status.data.get("approved") or {}).get("by")

    if action == "labeled" and event["label"]["name"] == label:
        updates = {"labeled": True, "removed": None, "final": None, "checking": True}
        # Triage members can add labels too, only write access approves
        if gh.write_access(sender):
            updates["approved"] = {"sha": pr["head"]["sha"], "by": sender, "at": t}
        status.save(updates)

    elif action == "unlabeled" and event["label"]["name"] == label:
        # Removing the label of a merged pull request is part of closing it
        if sender == BOT or pr.get("merged") or not status.id:
            return
        # Jobs can finish out of order, a removal is outdated when the label
        # was added again in the meantime
        if label in gh.pr_labels(pr["number"]):
            return
        status.save({"labeled": False, "removed": {"by": sender, "at": t}, "checking": False},
                    (f"removed:{t}", {status.author, approver} - {sender},
                     f"{sender} removed this pull request from staging"))

    elif action == "closed" and (label in labels or status.data.get("labeled")):
        if pr.get("merged"):
            merged_at = pr.get("merged_at") or t
            status.save({"labeled": False, "final": "merged", "checking": False, **close_period(status.data, merged_at)})
            if label in labels:
                gh.remove_label(pr["number"], label)
        else:
            status.save({"labeled": False, "final": "closed", "removed": {"by": sender, "at": t}, "checking": False})

    elif action in ("synchronize", "reopened") and label in labels:
        status.save({"labeled": True, "removed": None, "final": None, "checking": True})


def check(gh, cfg, mode="check", push=False, event=("", {})):
    """Merges all labeled pull requests and refreshes their status comments"""
    name, payload = event
    if not relevant(cfg, name, payload):
        print(f"The event does not concern {cfg['label']}")
        return
    branch, label = cfg["branch"], cfg["label"]
    summary = open(os.environ.get("GITHUB_STEP_SUMMARY", os.devnull), "a", encoding="utf-8")
    summary.write(f"### Pull requests labeled `{label}`\n")

    prs = gh.list_prs(label)
    base = git_out("rev-parse", "HEAD")
    head = base
    if not prs:
        summary.write("No pull requests found\n")
        print("No pull requests found")
        # The staging branch still follows develop
        if mode == "stage" and push:
            git("push", "origin", f"HEAD:{branch}", "--force")
        return

    # The heads are taken from the fetch, the listed heads may be outdated
    git("fetch", "--quiet", "origin", *[f"+pull/{p['number']}/head:refs/staging/pull/{p['number']}" for p in prs])

    # Decide which commit of each pull request is staged
    statuses, picks, checks = {}, {}, {}
    for p in prs:
        n = p["number"]
        latest = p["head"] = git_out("rev-parse", f"refs/staging/pull/{n}")
        status = statuses[n] = Status(gh, cfg, n, p["author"]).load()
        approved = (status.data.get("approved") or {}).get("sha")
        c = checks[n] = {"latest": latest}
        if gh.write_access(p["author"]):
            picks[n] = latest
        elif not approved:
            c.update(state="unapproved", approve=latest, approve_note="no commit is approved yet")
        elif commit_available(approved):
            picks[n] = approved
            if approved != latest:
                if is_ancestor(approved, latest):
                    note = plural(count_commits(approved, latest), "new commit")
                else:
                    note = f"the branch was rewritten since {approved[:7]}"
                c.update(approve=latest, approve_note=f"{note}, [compare]({REPO_URL}/pull/{n}/files/{approved}..{latest})")
        else:
            c.update(state="missing", missing=approved, approve=latest,
                     approve_note=f"the approved commit {approved[:7]} no longer exists")

    # Pull requests that share commits beyond develop with another labeled pull request
    related = {n: [] for n in picks}
    for a in picks:
        for b in picks:
            if a < b:
                shared = git("merge-base", picks[a], picks[b], ok=(0, 1)).stdout.strip()
                if shared and not is_ancestor(shared, base):
                    related[a].append(b)
                    related[b].append(a)

    # Merge in order of pull request number. Conflicts are attributed to
    # develop or to the pull requests merged before that touch the same files
    staged_files, conflicted_by = {}, {n: [] for n in picks}
    titles = {p["number"]: p["title"] for p in prs}
    # A changelog snippet that the changelog workflow rejects would fail the
    # whole deployment, so a pull request that adds one is left out
    for n, sha in picks.items():
        tree, files = merge(head, sha)
        if files is None:
            invalid = snippet_errors(tree, head)
            if invalid:
                checks[n].update(state="snippet", sha=sha, snippets=invalid)
                continue
            trailer = f"Staged from {REPO_URL}/pull/{n} at {sha}"
            if related[n]:
                shares = ", ".join(f"#{o}" for o in related[n])
                head = git_out("commit-tree", tree, "-p", head, "-p", sha, "-m", f"Merge #{n}: {titles[n]}",
                               "-m", f"Merged instead of squashed because it shares commits with {shares}", "-m", trailer)
            else:
                head = git_out("commit-tree", tree, "-p", head, "-m", f"{titles[n]} (#{n})", "-m", trailer)
            staged_files[n] = set(git_out("diff", "--name-only", f"{base}...{sha}").splitlines())
            checks[n]["state"], checks[n]["sha"] = "clean", sha
            continue

        develop_files = merge(base, sha)[1]
        if develop_files is not None:
            cause, files = "develop", develop_files
        else:
            cause = [o for o, touched in staged_files.items() if touched & set(files)]
            for o in cause:
                conflicted_by[o].append(n)
        lines = conflict_lines(files)
        key = hashlib.sha1(json.dumps([cause, sorted(files), lines]).encode()).hexdigest()[:12]
        checks[n].update(state="conflict", sha=sha, conflict={"cause": cause, "files": sorted(files), "lines": lines, "key": key})

    if mode == "stage":
        git("reset", "--quiet", "--hard", head)
        if push:
            git("push", "origin", f"HEAD:{branch}", "--force")

    # Who to notify depends on the event that triggered the check
    action = payload.get("action") if name == "pull_request_target" else None
    event_pr = (payload.get("pull_request") or {}).get("number")
    sender = (payload.get("sender") or {}).get("login")
    labeled_now = action == "labeled" and (payload.get("label") or {}).get("name") == label

    conflicts, snippets, unapproved = [], [], []
    for p in prs:
        n = p["number"]
        status, c = statuses[n], checks[n]
        c["conflicted_by"] = conflicted_by.get(n, [])
        deployed = status.data.get("deployed")
        if c.get("state") == "clean" and deployed and commit_available(deployed["sha"]):
            ahead, behind = count_commits(deployed["sha"], c["sha"]), count_commits(c["sha"], deployed["sha"])
            if ahead and behind:
                c["delta"] = f"{plural(ahead, 'new commit')}, {plural(behind, 'removed commit')}"
            elif ahead or behind:
                c["delta"] = plural(ahead, "new commit") if ahead else f"{plural(behind, 'commit')} behind"
            else:
                c["delta"] = "already deployed"

        approved = status.data.get("approved") or {}
        old_key = ((status.data.get("check") or {}).get("conflict") or {}).get("key")
        new_key = (c.get("conflict") or {}).get("key")
        notify = None
        if labeled_now and n == event_pr:
            notify = (f"labeled:{approved.get('at')}", [sender], "the check for staging finished")
        elif new_key and new_key != old_key:
            if action == "synchronize" and n == event_pr:
                notify = (f"conflict:{new_key}", [sender], "your latest push conflicts with what is staged")
            else:
                notify = (f"conflict:{new_key}", [p["author"], approved.get("by")], "a new merge conflict appeared")
        elif (action == "synchronize" and n == event_pr and c.get("state") == "snippet"
              and (status.data.get("check") or {}).get("snippets") != c["snippets"]):
            notify = (f"snippet:{c['latest']}", [sender], "your latest push has an invalid changelog snippet")
        elif action == "synchronize" and n == event_pr and c.get("approve") and c.get("state") == "clean":
            notify = (f"approve:{c['latest']}", [approved.get("by")], "new commits are waiting for approval")

        # The label state belongs to the record job, which may have changed it
        # since the pull requests were listed. Pull requests that were labeled
        # before status comments existed are marked here. A removal that was
        # recorded while the label was added again is undone, after asking for
        # the current labels, because record jobs can finish in any order
        updates = {"check": c, "checking": False}
        if "labeled" not in status.data:
            updates["labeled"] = True
        elif status.data.get("labeled") is False and not status.data.get("final") and label in gh.pr_labels(n):
            updates.update(labeled=True, removed=None)
        url = status.save(updates, notify)

        line = f"[#{n}]({REPO_URL}/pull/{n}): {p['title']}"
        if c.get("state") == "clean":
            summary.write(f"- Staged {line}\n" if mode == "stage" else f"- Merges cleanly {line}\n")
        elif c.get("state") == "conflict":
            conflicts.append(f"#{n} {p['title']}: {url}")
            summary.write(f"- Left out {line} due to a [merge conflict]({url})\n")
        elif c.get("state") == "snippet":
            snippets.append(f"#{n} {p['title']}: {url}")
            summary.write(f"- Left out {line} due to an [invalid changelog snippet]({url})\n")
        else:
            unapproved.append(f"#{n} {p['title']}: {url}")
            summary.write(f"- Left out {line} because it has [no approved commit]({url})\n")
        print(f"#{n}: {c.get('state')}")

    annotate(conflicts, "merge conflict", "merge conflicts")
    annotate(snippets, "invalid changelog snippet", "invalid changelog snippets")
    annotate(unapproved, "pull request without approved commit", "pull requests without approved commit")


def annotate(lines, singular, plural_text):
    if not lines:
        return
    title = f"{len(lines)} {singular if len(lines) == 1 else plural_text}"
    message = "%0A".join(line.replace("%", "%25") for line in lines)
    print(f"::warning title={title}::{message}")


def deploy(gh, cfg, result, staging, deployed_sha, previous, manual_by):
    """Records the outcome of a deployment on every pull request it concerns"""
    branch, label, t = cfg["branch"], cfg["label"], iso(now())
    staging = staging or git_out("rev-parse", f"origin/{branch}")
    included = staged_prs(staging)
    before = staged_prs(previous, skip_top=True) if previous and commit_available(previous) else {}
    labeled = {p["number"]: p for p in gh.list_prs(label)}

    for n in sorted(set(included) | set(before) | set(labeled)):
        status = Status(gh, cfg, n, labeled.get(n, {}).get("author")).load()
        if not status.id and n not in labeled:
            continue
        data, notify = status.data, None
        deployed = data.get("deployed")
        if result == "success":
            if n in included:
                sha = included[n]
                updates = close_period(data, t) if deployed and deployed["sha"] != sha else {}
                since = deployed["since"] if deployed and deployed["sha"] == sha else t
                updates.update(deployed={"sha": sha, "deploy_sha": deployed_sha, "at": t, "by": manual_by or None, "since": since},
                               failed=None, left_out=None)
            else:
                updates = {**close_period(data, t), "failed": None}
                if data.get("labeled"):
                    state = (data.get("check") or {}).get("state")
                    updates["left_out"] = {"reason": LEFT_OUT_REASONS.get(state, "it was not staged"), "at": t}
                    if state == "conflict":
                        approver = (data.get("approved") or {}).get("by")
                        notify = (f"left-out:{t}", [status.author, approver],
                                  "this pull request was left out of the deployment because of a merge conflict")
        elif n in included:
            reason = "tests failed" if result == "tests" else "the deploy run failed"
            updates = {"failed": {"reason": reason, "at": t, "run": RUN_URL}}
        else:
            continue
        status.save(updates, notify)

    # The next deployment moved, refresh the queue of all labeled pull requests
    check(gh, cfg)


def labels(gh, config):
    existing = {name.lower() for name in gh.labels()}
    for cfg in config:
        # An existing label is left alone so that manual edits are preserved
        if cfg["label"].lower() not in existing:
            gh.create_label(cfg["label"], cfg["color"], cfg["description"])
            print(f"Created label {cfg['label']}")


def workflow_cron(file):
    """The first schedule of a workflow, read with a regular expression
    because PyYAML is not guaranteed to be installed"""
    path = WORKFLOWS_PATH / file
    match = CRON_RE.search(path.read_text(encoding="utf-8"))
    if not match:
        raise ValueError(f"No schedule found in {path}")
    return match[1].strip()


def load_config():
    """The staging configuration. The display name is the label without its
    prefix and the schedules are read from the workflows so that they can not
    drift apart"""
    config = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    for cfg in config:
        cfg["name"] = cfg["label"].split(": ", 1)[-1]
        cfg["stage_cron"] = workflow_cron(cfg["stage_workflow"])
        cfg["deploy_cron"] = workflow_cron(cfg["deploy_workflow"])
    return config


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("command", choices=["stage", "check", "record", "deploy", "labels", "matrix"])
    parser.add_argument("branch", nargs="?")
    parser.add_argument("--push", action="store_true")
    parser.add_argument("--result", choices=["success", "tests", "failed"])
    parser.add_argument("--staging", default="")
    parser.add_argument("--deployed", default="")
    parser.add_argument("--previous", default="")
    parser.add_argument("--manual-by", default="")
    args = parser.parse_args(argv)

    config = load_config()
    gh = GitHub()
    if args.command == "labels":
        return labels(gh, config)
    if args.command == "matrix":
        event = load_event()
        print(json.dumps([c for c in config if relevant(c, *event)], separators=(",", ":")))
        return

    cfg = next((c for c in config if c["branch"] == args.branch), None)
    if cfg is None:
        parser.error(f"No label is configured for {args.branch} in {CONFIG_PATH}")

    if args.command == "stage":
        check(gh, cfg, "stage", args.push)
    elif args.command == "check":
        check(gh, cfg, event=load_event())
    elif args.command == "record":
        record(gh, cfg, *load_event())
    elif args.command == "deploy":
        if not args.result:
            parser.error("deploy requires --result")
        deploy(gh, cfg, args.result, args.staging, args.deployed, args.previous, args.manual_by)


if __name__ == "__main__":
    main()

#endregion
