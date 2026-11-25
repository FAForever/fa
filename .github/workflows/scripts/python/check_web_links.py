"""Check the web links in Markdown files over HTTP.

The links are extracted with urlchecker, like the urlchecker action does, but
each URL is requested only once, however many files link to it. The requests
to one host are made one after another and the hosts are checked in parallel,
so that a site isn't sent a burst of requests that it may block.

A link passes when the final response, after redirects, has status 200. The
error of a failed link names the status or the exception, so that a missing
page (404) can be told apart from a blocked request (403, 429) or a timeout.

Usage:
    python3 check_web_links.py --exclude docs/README.md \
        --exclude-urls https://example.com/a,https://example.com/b docs
"""

import argparse
import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from urllib.parse import urlsplit

import requests
from urlchecker.core.fileproc import collect_links_from_file
from urlchecker.core.urlproc import get_user_agent


def escape_data(value: str) -> str:
    """Escape a value for a workflow command message."""
    return value.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def escape_property(value: str) -> str:
    """Escape a value for a workflow command property."""
    return escape_data(value).replace(":", "%3A").replace(",", "%2C")


def markdown_files(folder: str, excluded: set[str]):
    for root, _, files in os.walk(folder):
        for name in sorted(files):
            if not name.endswith(".md"):
                continue
            file = os.path.join(root, name).replace(os.sep, "/")
            if os.path.normpath(file) not in excluded:
                yield file


def line_of(file: str, link: str) -> int:
    """Line number of the first occurrence of `link` in `file`."""
    with open(file, encoding="utf-8") as handle:
        content = handle.read()
    return content.count("\n", 0, max(content.find(link), 0)) + 1


def check(url: str, retry_count: int, timeout: float) -> str | None:
    """None when the URL responds with 200, otherwise the reason it failed."""
    reason = None
    pause = 2
    for attempt in range(retry_count):
        if attempt:
            time.sleep(pause)
            pause *= 2
        try:
            response = requests.get(url, timeout=timeout + attempt, headers=get_user_agent())
            if response.status_code == 200:
                return None
            reason = f"HTTP {response.status_code}"
        except requests.RequestException as error:
            reason = type(error).__name__
    return reason


def check_host(urls: list[str], retry_count: int, timeout: float) -> dict[str, str | None]:
    """Check the URLs of one host one after another."""
    return {url: check(url, retry_count, timeout) for url in urls}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("folder", help="folder with the Markdown files to check")
    parser.add_argument("--exclude", action="append", default=[], help="Markdown file to skip")
    parser.add_argument("--exclude-urls", action="append", default=[], help="comma-separated URLs to skip")
    parser.add_argument("--retry-count", type=int, default=1, help="attempts per URL (default: 1)")
    parser.add_argument("--timeout", type=float, default=5, help="seconds per request (default: 5)")
    parser.add_argument("--workers", type=int, default=8, help="hosts checked in parallel (default: 8)")
    args = parser.parse_args()

    excluded_files = {os.path.normpath(file) for file in args.exclude}
    excluded_urls = {url for value in args.exclude_urls for url in value.split(",") if url}

    # Each URL with the files that link to it.
    sources: dict[str, list[str]] = {}
    for file in markdown_files(args.folder, excluded_files):
        for url in collect_links_from_file(file):
            if url not in excluded_urls and url.startswith(("http://", "https://")):
                sources.setdefault(url, []).append(file)

    hosts: dict[str, list[str]] = {}
    for url in sorted(sources):
        hosts.setdefault(urlsplit(url).netloc.lower(), []).append(url)

    results: dict[str, str | None] = {}
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        for result in pool.map(lambda urls: check_host(urls, args.retry_count, args.timeout), hosts.values()):
            results.update(result)

    failed = {url: reason for url, reason in results.items() if reason}
    for url in sorted(results):
        print(f"  {'failed' if url in failed else 'ok':6}  {url}")
    print(f"Checked {len(results)} URLs on {len(hosts)} hosts, linked {sum(map(len, sources.values()))} times; {len(failed)} failed.")
    for url, reason in sorted(failed.items()):
        for file in sources[url]:
            message = f"{url} failed: {reason}"
            print(f"::error file={escape_property(file)},line={line_of(file, url)}::{escape_data(message)}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
