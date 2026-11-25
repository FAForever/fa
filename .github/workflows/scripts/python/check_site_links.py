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
from urllib.parse import unquote, urljoin, urlsplit

from link_check_utils import annotate, line_of
from urlchecker.core.fileproc import collect_links_from_file

# Front matter may be empty: two lines of `---` make Jekyll render the file as a page.
FRONT_MATTER = re.compile(r"\A---[ \t]*\r?\n(.*?)^---[ \t]*\r?(?:\n|\Z)", re.S | re.M)
PERMALINK = re.compile(r"^permalink:\s*[\"']?([^\"'\s]*)", re.M)

# Link destinations: inline Markdown links and images, reference definitions, and HTML attributes.
INLINE = re.compile(r"!?\[[^\]\n]*\]\(\s*(<[^>\n]*>|\{\{[^}\n]*\}\}|[^\s()]*(?:\([^\s()]*\)[^\s()]*)*)")
REFERENCE = re.compile(r"^ {0,3}\[[^\]\n]+\]:\s*(<[^>\n]*>|\{\{[^}\n]*\}\}|\S+)", re.M)
# The value ends at the quote that opened it, so `src="{{ 'x' | relative_url }}"` is read whole.
ATTRIBUTE = re.compile(r"\b(?:href|src)\s*=\s*([\"'])(?P<dest>(?:(?!\1)[^\n])*)\1")
RELATIVE_URL = re.compile(r"\{\{\s*[\"']([^\"']*)[\"']\s*\|\s*relative_url\s*\}\}")

# A fence closes with the same character, at least as many times as it opened with.
FENCE = re.compile(r"^ {0,3}((`|~)\2{2,})[^\n]*\n.*?^ {0,3}\1\2*[ \t]*$", re.M | re.S)
# An id in a kramdown attribute list, such as `{#id}` or `{: .class #id}`.
HEADING_ID = re.compile(r"\s*\{(?:#|:[^}]*?#)([\w-]+)[^}]*\}\s*$")
CODE_SPAN = re.compile(r"(`+)[^`].*?\1", re.S)
COMMENT = re.compile(r"<!--.*?-->", re.S)
SCHEME = re.compile(r"[a-zA-Z][\w+.-]*:|//")
DYNAMIC_HEADING = re.compile(r"^ {0,3}#.*\{\{|<h[1-6][^>]*\{\{", re.M)
ATX_HEADING = re.compile(r"^ {0,3}#{1,6}[ \t]+(.*?)(?:[ \t]+#+)?[ \t]*$", re.M)
SETEXT_HEADING = re.compile(r"^ {0,3}(\S[^\n]*)\n {0,3}(?:=+|-+)[ \t]*$", re.M)
EXPLICIT_ID = re.compile(r"\{(?:#|:[^}]*?#)([\w-]+)[^}]*\}|\bid\s*=\s*[\"']([^\"'{}]+)[\"']")


def heading_id(text: str) -> str:
    """The id that kramdown's GFM parser, the default on GitHub Pages, gives a heading."""
    text = re.sub(r"!?\[([^\]]*)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"<[^>]+>", "", text)
    # Remove emphasis markers outside code spans: `*` anywhere, `_` only at the edges of words.
    parts = re.split(r"(`+[^`]*`+)", text)
    for i in range(0, len(parts), 2):
        parts[i] = re.sub(r"(?<!\w)_+|_+(?!\w)", "", parts[i].replace("*", ""))
    text = "".join(part.strip("`") if i % 2 else part for i, part in enumerate(parts))
    return re.sub(r"[^\w\- ]", "", text.strip().lower()).replace(" ", "-")


def blank(pattern: re.Pattern, text: str) -> str:
    """Remove the matches of `pattern` but keep their line breaks, so that line numbers stay the same."""
    return pattern.sub(lambda m: "\n" * m.group(0).count("\n"), text)


# Any indentation, so that nested items are found. A marker indented as far as code is code.
LIST_ITEM = re.compile(r" *(?:[-*+]|\d+[.)])[ \t]+")


def blank_indented_code(text: str) -> str:
    """Blank code blocks indented by four spaces more than the content they belong to.

    Outside a list that is four spaces. In a list item the content starts after
    the marker, two spaces in for `- `, so a code block in it needs six.
    Lines indented less continue the list item and stay.
    """
    lines = text.split("\n")
    content_indent = 0
    in_code = False
    previous_blank = True
    for i, line in enumerate(lines):
        blank_line = not line.strip()
        expanded = line.expandtabs(4)
        indent = len(expanded) - len(expanded.lstrip())
        code_indent = content_indent + 4
        if in_code and (blank_line or indent >= code_indent):
            lines[i] = ""
        elif not blank_line and indent >= code_indent and previous_blank:
            in_code = True
            lines[i] = ""
        else:
            in_code = False
            if not blank_line:
                item = LIST_ITEM.match(expanded)
                if item:
                    content_indent = len(item.group(0))
                elif indent == 0:
                    content_indent = 0
        previous_blank = blank_line
    return "\n".join(lines)


class Page:
    def __init__(self, file: str, url: str, text: str):
        self.file = file
        self.url = url
        # The content that is rendered: without front matter, comments, and code blocks.
        self.text = blank_indented_code(blank(FENCE, blank(COMMENT, blank(FRONT_MATTER, text))))
        # Liquid tags, such as loops and includes, or Liquid in a heading can generate headings.
        # Liquid in inline code is only shown, so it doesn't count.
        without_code = blank(CODE_SPAN, self.text)
        self.dynamic = "{%" in without_code or bool(DYNAMIC_HEADING.search(without_code))
        self._ids = None

    @property
    def ids(self) -> set[str]:
        if self._ids is None:
            text = self.text
            self._ids = set()
            counts = {}
            headings = [(m.start(), m.group(1)) for m in ATX_HEADING.finditer(text)]
            headings += [(m.start(), m.group(1)) for m in SETEXT_HEADING.finditer(text) if not m.group(1).startswith(("|", "-", "#"))]
            for _, heading in sorted(headings):
                explicit = HEADING_ID.search(heading)
                if explicit:
                    # A heading with its own id doesn't take an automatic id or suffix.
                    self._ids.add(explicit.group(1))
                    continue
                base = heading_id(heading)
                count = counts.get(base, 0)
                counts[base] = count + 1
                self._ids.add(base if count == 0 else f"{base}-{count}")
            # An id written in inline code is only shown, not set.
            for match in EXPLICIT_ID.finditer(blank(CODE_SPAN, text)):
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


# Files that Jekyll doesn't publish by default, relative to the site folder, and
# posts, which are only published when they have front matter.
JEKYLL_EXCLUDES = ("Gemfile", "gemfiles/", "node_modules/", "vendor/bundle/", "vendor/cache/", "vendor/gems/", "vendor/ruby/", "_posts/")


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
            if not name.startswith((".", "_")) and not relative.startswith(JEKYLL_EXCLUDES):
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
            # Browsers ignore whitespace around a link destination, such as in `href=" x "`.
            dest = match.group("dest") if "dest" in pattern.groupindex else match.group(1)
            value = dest.strip().strip("<>").strip()
            line = text.count("\n", 0, match.start(1)) + 1
            liquid = RELATIVE_URL.fullmatch(value)
            if liquid:
                yield line, "/" + liquid.group(1).lstrip("/"), "liquid"
            elif "{" not in value and not SCHEME.match(value):
                yield line, value, "local"


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
            try:
                parts = urlsplit(value)
            except ValueError:
                continue  # Not a valid URL, which the web link check reports.
            if parts.netloc.lower() == site.netloc.lower() and (parts.path == base_path or parts.path.startswith(base_path + "/")):
                links.append((line_of(page.file, value), value, "absolute"))

        for line, value, kind in links:
            try:
                parts = urlsplit(value)
                if kind == "absolute":
                    reference = parts.path
                elif kind == "liquid":
                    reference = base_path + parts.path  # relative_url adds the base path.
                else:
                    reference = value

                # Resolve like a browser, against the published URL of the page, so that
                # dot segments are removed before the base path is checked.
                resolved = urlsplit(urljoin(f"{base_path}/{page.url.lstrip('/')}", reference)).path
            except ValueError as error:
                # Such as an unclosed `[` in the host, which Python reads as an IPv6 address.
                errors.append((page.file, line, value, f"is not a valid URL: {error}"))
                continue
            if not (resolved == base_path or resolved.startswith(base_path + "/")):
                if kind == "local" and value.startswith("/") and not value.startswith(base_path + "/"):
                    reason = f"misses the base path {base_path} of the site; use relative_url"
                else:
                    reason = f"resolves to {resolved}, outside the base path {base_path} of the site"
                errors.append((page.file, line, value, reason))
                continue
            if kind == "absolute":
                # Only links within the site are left out of the URL check.
                absolute.add(value)
            target = resolved[len(base_path):]

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
        annotate("warning", file, line, f"{value}: {reason}")
    for file, line, value, reason in sorted(errors):
        annotate("error", file, line, f"{value}: {reason}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
