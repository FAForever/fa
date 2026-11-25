"""Check the links between the pages of the documentation site.

The documentation is a Jekyll site that is published at `--site-url`. A link
between its pages resolves against the URL of the page, which comes from its
`permalink`, not against the path of the Markdown file. The script resolves
these links locally, so that a link to a page that the pull request adds
passes, and a link to a page or heading that doesn't exist fails:

- relative links, such as `[text](../changelog)` or `[text](#a-heading)`
- links in the form of `{{ 'assets/image.png' | relative_url }}`
- absolute links to the site, such as `https://faforever.github.io/fa/changelog`

A heading in a link must match the id of a heading on the target page.

The URL check excludes the absolute links to the site that this script checked,
so the script writes them to `$GITHUB_OUTPUT` as `exclude_urls`.

Usage:
    python3 check_site_links.py --site-url https://faforever.github.io/fa \
        --exclude docs/README.md docs
"""

import argparse
import os
import posixpath
import re
import sys
from urllib.parse import unquote, urlsplit

from urlchecker.core.fileproc import collect_links_from_file

FRONT_MATTER = re.compile(r"\A---\s*\n(.*?)\n---\s*\n", re.S)
PERMALINK = re.compile(r"^permalink:\s*[\"']?([^\"'\s]*)", re.M)

# Link destinations: inline Markdown links and images, reference definitions, and HTML attributes.
INLINE = re.compile(r"!?\[[^\]\n]*\]\(\s*(<[^>\n]*>|\{\{[^}\n]*\}\}|[^\s()]*(?:\([^\s()]*\)[^\s()]*)*)")
REFERENCE = re.compile(r"^ {0,3}\[[^\]\n]+\]:\s*(<[^>\n]*>|\S+)", re.M)
ATTRIBUTE = re.compile(r"\b(?:href|src)\s*=\s*[\"']([^\"'\n]*)[\"']")
RELATIVE_URL = re.compile(r"\{\{\s*[\"']([^\"']*)[\"']\s*\|\s*relative_url\s*\}\}")

FENCE = re.compile(r"^ {0,3}(```|~~~).*?^ {0,3}\1", re.M | re.S)
CODE_SPAN = re.compile(r"(`+)[^`].*?\1", re.S)
COMMENT = re.compile(r"<!--.*?-->", re.S)
SCHEME = re.compile(r"[a-zA-Z][\w+.-]*:|//")
DYNAMIC_HEADING =re.compile(r"^ {0,3}#.*\{\{|<h[1-6][^>]*\{\{", re.M)
ATX_HEADING = re.compile(r"^ {0,3}#{1,6}[ \t]+(.*?)(?:[ \t]+#+)?[ \t]*$", re.M)
SETEXT_HEADING = re.compile(r"^ {0,3}(\S[^\n]*)\n {0,3}(?:=+|-+)[ \t]*$", re.M)
EXPLICIT_ID = re.compile(r"\{:?\s*#([\w-]+)\s*\}|\bid\s*=\s*[\"']([^\"'{}]+)[\"']")


def escape_data(value: str) -> str:
    """Escape a value for a workflow command message."""
    return value.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def escape_property(value: str) -> str:
    """Escape a value for a workflow command property."""
    return escape_data(value).replace(":", "%3A").replace(",", "%2C")


def heading_id(text: str) -> str:
    """The id that kramdown's GFM parser, the default on GitHub Pages, gives a heading."""
    text = re.sub(r"\{:?\s*#[\w-]+\s*\}\s*$", "", text)
    text = re.sub(r"!?\[([^\]]*)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"<[^>]+>", "", text)
    text = text.replace("`", "").replace("*", "")
    return re.sub(r"[^\w\- ]", "", text.strip().lower()).replace(" ", "-")


def blank(pattern: re.Pattern, text: str) -> str:
    """Remove the matches of `pattern` but keep their line breaks, so that line numbers stay the same."""
    return pattern.sub(lambda m: "\n" * m.group(0).count("\n"), text)


class Page:
    def __init__(self, file: str, url: str, text: str):
        self.file = file
        self.url = url
        # The content that is rendered: without front matter, comments, and code blocks.
        self.text = blank(FENCE, blank(COMMENT, blank(FRONT_MATTER, text)))
        # Liquid tags, such as loops and includes, or Liquid in a heading can generate headings.
        self.dynamic = "{%" in self.text or bool(DYNAMIC_HEADING.search(self.text))
        self._ids = None

    @property
    def ids(self) -> set[str]:
        if self._ids is None:
            text = self.text
            self._ids = set()
            counts = {}
            headings = [m.group(1) for m in ATX_HEADING.finditer(text)]
            headings += [m.group(1) for m in SETEXT_HEADING.finditer(text) if not m.group(1).startswith(("|", "-", "#"))]
            for heading in headings:
                base = heading_id(heading)
                count = counts.get(base, 0)
                counts[base] = count + 1
                self._ids.add(base if count == 0 else f"{base}-{count}")
            for match in EXPLICIT_ID.finditer(text):
                self._ids.add(match.group(1) or match.group(2))
        return self._ids


def normalize(url_path: str) -> str:
    """A site path without the leading slash, trailing slash, or `.html`, so that equivalent URLs compare equal."""
    path = posixpath.normpath("/" + url_path).lstrip("/")
    if path in (".", ""):
        return ""
    for suffix in ("/index.html", ".html"):
        if path.endswith(suffix):
            path = path[: -len(suffix)]
    return "" if path == "index" else path


def load_site(folder: str) -> tuple[dict[str, Page], set[str]]:
    """The pages of the site by their normalized URL, and the paths of the static files."""
    pages = {}
    files = set()
    for root, dirs, names in os.walk(folder):
        dirs[:] = [d for d in dirs if not d.startswith(("_", ".")) or d == "_posts"]
        for name in names:
            file = os.path.join(root, name).replace(os.sep, "/")
            relative = posixpath.relpath(file, folder)
            if name.endswith((".md", ".html")):
                with open(file, encoding="utf-8") as handle:
                    text = handle.read()
                front = FRONT_MATTER.match(text)
                if front:
                    permalink = PERMALINK.search(front.group(1))
                    if permalink:
                        url = permalink.group(1)
                    elif relative.startswith("_posts/"):
                        continue  # Posts without a permalink use the date in their URL. None exist.
                    else:
                        url = re.sub(r"\.md$", ".html", relative)
                    pages[normalize(url)] = Page(file, url, text)
                    continue
            if not name.startswith((".", "_")):
                files.add(relative)
    return pages, files


def local_links(page: Page):
    """Links without a scheme, with their line number and kind, outside code.

    The kind is "liquid" for `{{ '<path>' | relative_url }}`, with the path as
    the value, and "local" for the others. Other Liquid expressions can't be
    resolved without building the site and are skipped.
    """
    text = blank(CODE_SPAN, page.text)
    for pattern in (INLINE, REFERENCE, ATTRIBUTE):
        for match in pattern.finditer(text):
            value = match.group(1).strip("<>")
            line = text.count("\n", 0, match.start(1)) + 1
            liquid = RELATIVE_URL.fullmatch(value)
            if liquid:
                yield line, "/" + liquid.group(1).lstrip("/"), "liquid"
            elif "{" not in value and not SCHEME.match(value):
                yield line, value, "local"


def line_of(file: str, value: str) -> int:
    """Line number of the first occurrence of `value` in `file`."""
    with open(file, encoding="utf-8") as handle:
        content = handle.read()
    return content.count("\n", 0, max(content.find(value), 0)) + 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("folder", help="source folder of the Jekyll site")
    parser.add_argument("--site-url", required=True, help="URL that the site is published at, such as https://faforever.github.io/fa")
    parser.add_argument("--exclude", action="append", default=[], help="Markdown file to skip")
    args = parser.parse_args()

    site = urlsplit(args.site_url.rstrip("/"))
    base_path = site.path  # GitHub Pages serves a project site below /<repository>.
    pages, files = load_site(args.folder)
    excluded = {os.path.normpath(file) for file in args.exclude}

    checked = 0
    absolute = set()
    errors = []
    warnings = []
    for page in pages.values():
        if os.path.normpath(page.file) in excluded:
            continue
        links = list(local_links(page))
        # Absolute links are extracted with urlchecker, so that the URL check can exclude exactly these.
        for value in collect_links_from_file(page.file):
            parts = urlsplit(value)
            if parts.netloc.lower() == site.netloc.lower() and (parts.path == base_path or parts.path.startswith(base_path + "/")):
                links.append((line_of(page.file, value), value, "absolute"))

        for line, value, kind in links:
            parts = urlsplit(value)
            if kind == "absolute":
                target = parts.path[len(base_path):]
                absolute.add(value)
            elif kind == "liquid":
                target = parts.path
            elif value.startswith("/"):
                if not (parts.path == base_path or parts.path.startswith(base_path + "/")):
                    errors.append((page.file, line, value, f"misses the base path {base_path} of the site; use relative_url"))
                    continue
                target = parts.path[len(base_path):]
            else:
                target = posixpath.join(posixpath.dirname("/" + page.url.lstrip("/")), parts.path) if parts.path else "/" + page.url.lstrip("/")

            checked += 1
            path = unquote(target)
            key = normalize(path)
            fragment = unquote(parts.fragment)
            if key in pages:
                target_page = pages[key]
                if fragment and fragment not in target_page.ids:
                    reason = f"'{target_page.file}' has no heading with the id '{fragment}'"
                    if target_page.dynamic:
                        # Liquid can generate headings, which can't be known without building the site.
                        warnings.append((page.file, line, value, reason + ", unless Liquid generates it"))
                    else:
                        errors.append((page.file, line, value, reason))
            elif posixpath.normpath(path).lstrip("/") not in files:
                errors.append((page.file, line, value, f"'{posixpath.normpath(path)}' is not a page or file of the site"))

    output = os.environ.get("GITHUB_OUTPUT")
    if output:
        with open(output, "a", encoding="utf-8") as handle:
            handle.write(f"exclude_urls={','.join(sorted(u for u in absolute if ',' not in u))}\n")

    print(f"Checked {checked} links between {len(pages)} pages and {len(files)} files of the site.")
    for file, line, value, reason in sorted(warnings):
        print(f"::warning file={escape_property(file)},line={line}::{escape_data(f'{value}: {reason}')}")
    for file, line, value, reason in sorted(errors):
        print(f"::error file={escape_property(file)},line={line}::{escape_data(f'{value}: {reason}')}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
