#!/bin/bash

# -----------------------------------------------------------------------------
# Copyright (c) 2024 FAForever
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
#region Verify that the script has everything it needs.

# The primary check is whether we launched the script from the correct
# directory. The active directory should always be '(...)/fa/changelog/snippets'

#endregion

# -----------------------------------------------------------------------------
#region Reporting

# Prints an error as a GitHub Actions workflow command, which shows it as an
# annotation on the workflow run summary and on the file in the pull request.
# Outside of GitHub Actions it is printed as a regular line.
annotate_error() {
    local file="$1"
    local title="$2"
    local message="$3"
    echo "::error file=$file,title=$title::$message"
}

#endregion

# -----------------------------------------------------------------------------
#region Verify that no snippets are placed in the parent folder

# Snippets that are accidentally created in 'changelog/' instead of
# 'changelog/snippets/' are never bundled, so the entry silently goes missing
# from the changelog. Anything there that looks like a snippet is an error.
# The legitimate content of 'changelog/' (template.md and the snippets folder)
# does not match the pattern.

misplaced_found=0
for file in ../*.md; do
    [[ -f "$file" ]] || continue
    filename="${file##*/}"
    if [[ "$filename" =~ ^[A-Za-z]+\.([0-9]+|\<number\>)\.md$ ]]; then
        annotate_error "changelog/$filename" "Misplaced snippet" \
            "changelog/$filename is not in changelog/snippets/, so it would be left out of the changelog. Move it into changelog/snippets/."
        misplaced_found=1
    fi
done

# Misplaced snippets fail the verification at the end, so that invalid snippet
# names are reported in the same run.

#endregion

# -----------------------------------------------------------------------------
#region Verify that there are snippets to verify

if ! ls *.md >/dev/null 2>&1; then
    echo "No Markdown files found to verify."
    exit $misplaced_found
fi

#endregion

# -----------------------------------------------------------------------------
#region Verify the snippets whether they match the convention

categories="fix|balance|features|graphics|ai|performance|other"

# Function to process snippets file names
is_valid_filename() {
    local filename="$1"

    # Pattern to match: starts with 'fix', 'graphics', etc.,
    # followed by a dot, then 1 to 5 digits, and ends with '.md'
    if [[ "$filename" =~ ^($categories)\.[0-9]{1,5}\.md$ ]]; then
        return 0
    else
        return 1
    fi
}

# Report every invalid snippet instead of stopping at the first one
invalid_found=0
for file in *.md; do
    if is_valid_filename "$file"; then
        echo " - Verified: $file"
    else
        annotate_error "changelog/snippets/$file" "Invalid snippet name" \
            "changelog/snippets/$file does not match <category>.<pr number>.md, where the category is one of: ${categories//|/, }."
        invalid_found=1
    fi
done

if [[ $misplaced_found -ne 0 || $invalid_found -ne 0 ]]; then
    exit 1
fi

echo "All snippets are formatted correctly."

#endregion
