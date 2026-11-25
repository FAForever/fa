"""Helpers shared by the link check scripts of the documentation workflow."""

import os
import re


def escape_data(value: str) -> str:
    """Escape a value for a workflow command message."""
    return value.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def escape_property(value: str) -> str:
    """Escape a value for a workflow command property."""
    return escape_data(value).replace(":", "%3A").replace(",", "%2C")


def annotate(severity: str, file: str, line: int, message: str) -> None:
    """Print a workflow command that shows `message` at the line of the file, such as an error or a warning."""
    print(f"::{severity} file={escape_property(file)},line={line}::{escape_data(message)}")


def markdown_files(folder: str, excluded: set[str]):
    """The Markdown files below `folder`, except the ones in `excluded` (normalized paths)."""
    for root, _, files in os.walk(folder):
        for name in sorted(files):
            if not name.endswith(".md"):
                continue
            file = os.path.join(root, name).replace(os.sep, "/")
            if os.path.normpath(file) not in excluded:
                yield file


def line_of(file: str, value: str) -> int:
    """Line number of the first occurrence of `value` in `file` that isn't the start of a longer URL."""
    with open(file, encoding="utf-8") as handle:
        content = handle.read()
    # A period ends a sentence unless more of the URL follows it.
    match = re.search(re.escape(value) + r"(?![\w/#?%~=&+-]|[.,;:!][\w/])", content)
    return content.count("\n", 0, match.start() if match else 0) + 1
