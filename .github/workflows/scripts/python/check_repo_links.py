"""Check links to files of this repository against the checked out commit.

Links such as `https://github.com/<repository>/blob/<branch>/<path>` and
`https://github.com/<repository>/tree/<branch>/<path>` are valid when `<path>`
exists in the commit that is checked out. On a pull request that is the merge
commit, so a link to a file that the pull request adds passes, while a link to
a file that does not exist after the merge fails.

The links are extracted with urlchecker, the same package that the URL check
uses, so the script sees the same URLs. It writes the URLs that it checked to
`$GITHUB_OUTPUT` as `exclude_urls`, so that the URL check skips exactly those.

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

from link_check_utils import annotate, line_of, markdown_files
from urlchecker.core.fileproc import collect_links_from_file


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

    prefixes = tuple(f"https://github.com/{args.repository}/{kind}/{args.branch}/" for kind in ("blob", "tree"))
    excluded = {os.path.normpath(file) for file in args.exclude}
    checked = set()
    missing = []
    for file in markdown_files(args.folder, excluded):
        for link in collect_links_from_file(file):
            # The URL check splits its exclusions at commas, so such links are left to it.
            if not link.startswith(prefixes) or "," in link:
                continue
            prefix = next(p for p in prefixes if link.startswith(p))
            path = unquote(re.split("[#?]", link[len(prefix):], maxsplit=1)[0])
            checked.add(link)
            if path_exists(args.rev, path):
                print(f"  ok      {link}")
            else:
                print(f"  missing {link}")
                missing.append((file, link, path))

    # The URL check runs even when this check fails, and skips the links that this check reported.
    output = os.environ.get("GITHUB_OUTPUT")
    if output:
        with open(output, "a", encoding="utf-8") as handle:
            handle.write(f"exclude_urls={','.join(sorted(checked))}\n")

    print(f"Checked {len(checked)} links to {' and '.join(prefixes)} against {args.rev}.")
    for file, link, path in missing:
        annotate("error", file, line_of(file, link), f"'{path}' does not exist in the checked out commit: {link}")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
