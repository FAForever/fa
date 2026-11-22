"""Check links to files of this repository against the checked out commit.

Links such as `https://github.com/<repository>/blob/<branch>/<path>` and
`https://github.com/<repository>/tree/<branch>/<path>` are valid when `<path>`
exists in the commit that is checked out. On a pull request that is the merge
commit, so a link to a file that the pull request adds passes, while a link to
a file that does not exist after the merge fails.

The URL check excludes these links by pattern, so the script writes the
patterns to `$GITHUB_OUTPUT` as `exclude_patterns`.

Usage:
    python3 check_repo_links.py --repository FAForever/fa --branch develop \
        --exclude docs/README.md docs
"""

import argparse
import functools
import os
import re
import subprocess
import sys
from urllib.parse import unquote

# Characters that end a URL in Markdown or HTML.
URL_END = r"\s()\[\]<>\"'`"


def escape_data(value: str) -> str:
    """Escape a value for a workflow command message."""
    return value.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def escape_property(value: str) -> str:
    """Escape a value for a workflow command property."""
    return escape_data(value).replace(":", "%3A").replace(",", "%2C")


@functools.cache
def path_exists(rev: str, path: str) -> bool:
    """Whether a file or folder exists at `path` in the tree of `rev`."""
    path = path.strip("/")
    if path == "":
        return True
    if any(part in ("", ".", "..") for part in path.split("/")):
        return False
    result = subprocess.run(
        ["git", "--literal-pathspecs", "ls-tree", "-z", "--name-only", "--full-tree", rev, "--", path],
        capture_output=True,
        text=True,
        check=True,
    )
    return path in result.stdout.split("\0")


def markdown_files(folder: str, excluded: set[str]):
    for root, _, files in os.walk(folder):
        for name in sorted(files):
            if not name.endswith(".md"):
                continue
            file = os.path.join(root, name).replace(os.sep, "/")
            if os.path.normpath(file) not in excluded:
                yield file


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("folder", help="folder with the Markdown files to check")
    parser.add_argument("--repository", default=os.environ.get("GITHUB_REPOSITORY"), help="owner/name")
    parser.add_argument("--branch", required=True, help="branch whose links are checked against --rev")
    parser.add_argument("--rev", default="HEAD", help="commit to look up the paths in (default: HEAD)")
    parser.add_argument("--exclude", action="append", default=[], help="Markdown file to skip")
    args = parser.parse_args()

    if not args.repository:
        parser.error("--repository is required when GITHUB_REPOSITORY is not set")

    prefixes = [f"https://github.com/{args.repository}/{kind}/{args.branch}/" for kind in ("blob", "tree")]
    url = re.compile("(?:%s)([^%s]*)" % ("|".join(re.escape(p) for p in prefixes), URL_END))

    # Write the patterns first so that the URL check skips these links even when this check fails.
    output = os.environ.get("GITHUB_OUTPUT")
    if output:
        with open(output, "a", encoding="utf-8") as file:
            file.write(f"exclude_patterns={','.join(prefixes)}\n")

    excluded = {os.path.normpath(file) for file in args.exclude}
    checked = 0
    missing = []
    for file in markdown_files(args.folder, excluded):
        with open(file, encoding="utf-8") as handle:
            for number, line in enumerate(handle, start=1):
                for match in url.finditer(line):
                    link = match.group(0).rstrip(".,;:!?")
                    path = unquote(re.split("[#?]", match.group(1), maxsplit=1)[0].rstrip(".,;:!?"))
                    checked += 1
                    if path_exists(args.rev, path):
                        print(f"  ok      {link}")
                    else:
                        print(f"  missing {link}")
                        missing.append((file, number, link, path))

    print(f"Checked {checked} links to {' and '.join(prefixes)} against {args.rev}.")
    for file, number, link, path in missing:
        message = f"'{path}' does not exist in the checked out commit: {link}"
        print(f"::error file={escape_property(file)},line={number}::{escape_data(message)}")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
