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

if ! ls *.md >/dev/null 2>&1; then
    echo "No Markdown files found to verify. Are you looking in the wrong directory?"
    exit 1
fi

#endregion

# -----------------------------------------------------------------------------
#region Verify the snippets whether they match the convention

# Function to process snippets file names
is_valid_filename() {
    local filename="$1"

    # Pattern to match: starts with 'fix', 'graphics', etc.,
    # followed by a dot, then 1 to 5 digits, and ends with '.md'
    if [[ "$filename" =~ ^(fix|graphics|performance|ai|features|other|performance|balance)\.[0-9]{1,5}\.md$ ]]; then
        return 0
    else
        return 1
    fi
}

for file in *.md; do
    if is_valid_filename "$file"; then
        echo " - Verified: $file"
    else
        echo "Invalid format: $file"
        exit 1
    fi
done

echo "All snippets are formatted correctly."

#endregion
