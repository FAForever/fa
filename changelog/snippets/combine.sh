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

templateHeader="sections/template-header.md"
if ! [ -e "$templateHeader" ]; then
    echo "No markdown template for the header found. Are you starting the script from the wrong directory?"
    exit 1
fi

templateFooter="sections/template-footer.md"
if ! [ -e "$templateFooter" ]; then
    echo "No markdown template for the footer found. Are you starting the script from the wrong directory?"
    exit 1
fi

templateFix="sections/template-fix.md"
if ! [ -e "$templateFix" ]; then
    echo "No markdown template for bug fixes found. Are you starting the script from the wrong directory?"
    exit 1
fi

templateBalance="sections/template-balance.md"
if ! [ -e "$templateBalance" ]; then
    echo "No markdown template for balance changes found. Are you starting the script from the wrong directory?"
    exit 1
fi

templateFeatures="sections/template-features.md"
if ! [ -e "$templateFeatures" ]; then
    echo "No markdown template for features found. Are you starting the script from the wrong directory?"
    exit 1
fi

templateGraphics="sections/template-graphics.md"
if ! [ -e "$templateGraphics" ]; then
    echo "No markdown template for graphics changes found. Are you starting the script from the wrong directory?"
    exit 1
fi

templateAI="sections/template-ai.md"
if ! [ -e "$templateAI" ]; then
    echo "No markdown template for ai changes found. Are you starting the script from the wrong directory?"
    exit 1
fi

templatePerformance="sections/template-performance.md"
if ! [ -e "$templatePerformance" ]; then
    echo "No markdown template for performance found. Are you starting the script from the wrong directory?"
    exit 1
fi

templateOther="sections/template-other.md"
if ! [ -e "$templateOther" ]; then
    echo "No markdown template for other changes found. Are you starting the script from the wrong directory?"
    exit 1
fi

if ! ls *.md >/dev/null 2>&1; then
    echo "No Markdown files found to combine. Are you looking in the wrong directory?"
    exit 1
fi

#endregion

# -----------------------------------------------------------------------------
#region Combine the changelog snippets into one large changelog

# Function to process snippets
process_snippets() {
    local snippet_type="$1"
    local template_file="$2"
    local output_file="$3"

    if ls "$snippet_type".*.md >/dev/null 2>&1; then
        echo "Processing $snippet_type snippets"
        cat "$template_file" >> "$output_file"
        echo "" >> "$output_file"

        for file in "$snippet_type".*.md; do
            echo " - Processing $snippet_type snippet: $file"
            cat "$file" >> "$output_file"
            echo "" >> "$output_file"
        done

        echo ""
        echo "" >> "$output_file"
    else
        echo "No $snippet_type snippets found."
        echo ""
    fi
}

# Output file name
output="changelog.md"
rm -f "$output"

# Add the initial header
cat "$templateHeader" >>"$output"

process_snippets "fix" "$templateFix" "$output"
process_snippets "balance" "$templateBalance" "$output"
process_snippets "features" "$templateFeatures" "$output"
process_snippets "graphics" "$templateGraphics" "$output"
process_snippets "ai" "$templateAI" "$output"
process_snippets "performance" "$templatePerformance" "$output"
process_snippets "other" "$templateOther" "$output"

# Add the final footer
cat "$templateFooter" >>"$output"

#endregion
