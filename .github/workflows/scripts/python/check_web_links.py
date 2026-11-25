"""Check the web links in Markdown files over HTTP.

The links are extracted with urlchecker, like the urlchecker action does, but
each URL is requested only once, however many files link to it. The requests
to one host are made one after another and the hosts are checked in parallel,
so that a site isn't sent a burst of requests that it may block.

A link passes when the final response, after redirects, has status 200. A link
to a missing page (404, 410) or a host that can't be reached fails. Sites
often block automated requests (401, 403, 429), and a server error (5xx) or a
timeout can be temporary, so those are reported as warnings. The urlchecker
action passed them too: it loaded them in a browser and accepted any page
with a title, such as a bot challenge.

Usage:
    python3 check_web_links.py --exclude docs/README.md \
        --exclude-urls https://example.com/a,https://example.com/b docs
"""

import argparse
import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from urllib.parse import urldefrag, urlsplit

import requests
from link_check_utils import annotate, line_of, markdown_files
from urlchecker.core.fileproc import collect_links_from_file
from urlchecker.core.urlproc import get_user_agent


# Statuses that mean the page doesn't exist. Other failing statuses may be a blocked or temporary failure.
MISSING = {404, 410}


def check(url: str, retry_count: int, timeout: float) -> tuple[str, str] | None:
    """None when the URL responds with 200, otherwise the severity ("error" or "warning") and the reason."""
    result = None
    pause = 2
    for attempt in range(retry_count):
        if attempt:
            time.sleep(pause)
            pause *= 2
        try:
            # Only the status is needed, so the body isn't downloaded.
            with requests.get(url, timeout=timeout + attempt, headers=get_user_agent(), stream=True) as response:
                status = response.status_code
            if status == 200:
                return None
            severity = "error" if status in MISSING else "warning"
            result = (severity, f"HTTP {status}")
            if severity == "error":
                return result
        except requests.Timeout as error:
            result = ("warning", type(error).__name__)
        except requests.ConnectionError as error:
            # Includes hosts that don't resolve anymore.
            result = ("error", type(error).__name__)
        except requests.RequestException as error:
            # Such as too many redirects: the page may still work in a browser.
            result = ("warning", type(error).__name__)
    return result


def check_host(urls: list[str], retry_count: int, timeout: float) -> dict[str, tuple[str, str] | None]:
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
    if args.retry_count < 1:
        parser.error("--retry-count must be at least 1")

    excluded_files = {os.path.normpath(file) for file in args.exclude}
    excluded_urls = {url for value in args.exclude_urls for url in value.split(",") if url}

    # Each URL with the files that link to it.
    sources: dict[str, list[str]] = {}
    for file in markdown_files(args.folder, excluded_files):
        for url in collect_links_from_file(file):
            if url not in excluded_urls and url.startswith(("http://", "https://")):
                sources.setdefault(url, []).append(file)

    # The fragment isn't sent to the server, so links that differ only in it share one request.
    page_of: dict[str, str] = {}
    invalid: dict[str, tuple[str, str]] = {}
    for url in sources:
        try:
            page_of[url] = urldefrag(url).url
        except ValueError as error:
            # Such as an unclosed `[` in the host, which Python reads as an IPv6 address.
            invalid[url] = ("error", f"not a valid URL ({error})")
    pages = sorted(set(page_of.values()))
    hosts: dict[str, list[str]] = {}
    for page in pages:
        hosts.setdefault(urlsplit(page).netloc.lower(), []).append(page)

    page_results: dict[str, tuple[str, str] | None] = {}
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        for result in pool.map(lambda urls: check_host(urls, args.retry_count, args.timeout), hosts.values()):
            page_results.update(result)
    results = {url: page_results[page] for url, page in page_of.items()} | invalid

    labels = {None: "ok", "warning": "warning", "error": "failed"}
    for url in sorted(results):
        print(f"  {labels[results[url] and results[url][0]]:7}  {url}")
    counts = {severity: sum(1 for r in results.values() if r and r[0] == severity) for severity in ("error", "warning")}
    print(
        f"Checked {len(pages)} pages on {len(hosts)} hosts for {len(results)} URLs, linked {sum(map(len, sources.values()))} times; "
        f"{counts['error']} failed, {counts['warning']} possibly blocked."
    )
    for url, result in sorted(results.items()):
        if not result:
            continue
        severity, reason = result
        message = f"{url} failed: {reason}" if severity == "error" else f"{url} could not be confirmed: {reason}, possibly blocked or temporary"
        for file in sources[url]:
            annotate(severity, file, line_of(file, url), message)
    return 1 if counts["error"] else 0


if __name__ == "__main__":
    sys.exit(main())
