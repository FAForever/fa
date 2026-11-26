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

# The script runs from `changelog/snippets`

shopt -s nullglob

# -----------------------------------------------------------------------------
#region Reporting

# GitHub Actions shows `::error` lines as annotations on the run and on the file in the pull request
annotate_error() {
    local file="$1"
    local title="$2"
    local message="$3"

    file="$(escape_data "$file")"
    file="${file//:/%3A}"
    file="${file//,/%2C}"
    echo "::error file=$file,title=$title::$(escape_data "$message")"
}

# workflow command values must escape these characters
escape_data() {
    local value="${1//'%'/%25}"
    value="${value//$'\r'/%0D}"
    echo "${value//$'\n'/%0A}"
}

#endregion

# -----------------------------------------------------------------------------
#region Verify that no snippets are in `changelog/`, which is not bundled

# in a variable so that `<` and `>` reach the regex as literals
misplaced_pattern='^[A-Za-z]+\.([0-9]+|<number>)\.md$'

misplaced_found=0
for file in ../*.md; do
    filename="${file##*/}"
    if [[ "$filename" =~ $misplaced_pattern ]]; then
        annotate_error "changelog/$filename" "Misplaced snippet" \
            "changelog/$filename is not in changelog/snippets/, so it would be left out of the changelog. Move it into changelog/snippets/."
        misplaced_found=1
    fi
done

#endregion

# -----------------------------------------------------------------------------
#region Verify the snippets whether they match the convention

categories="fix|balance|features|graphics|ai|performance|other"

# Function to process snippets file names
is_valid_filename() {
    # Pattern to match: starts with 'fix', 'graphics', etc.,
    # followed by a dot, then 1 to 5 digits, and ends with '.md'
    [[ "$1" =~ ^($categories)\.[0-9]{1,5}\.md$ ]]
}

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
