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
if ! [ -e "$templateHeader" ]; then
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

# Output file name
output="changelog.md"
rm -f "$output"

# Add the initial header
cat "$templateHeader" >>"$output"

# Add bug fixes
if ls fix.*.md >/dev/null 2>&1; then

    cat "$templateFix" >>"$output"
    echo "" >>"$output"

    for file in fix.*.md; do
        cat "$file" >>"$output"
        echo "" >>"$output"
    done

    echo "" >>"$output"
fi

# Add balance changes
if ls balance.*.md >/dev/null 2>&1; then

    cat "$templateBalance" >>"$output"
    echo "" >>"$output"

    for file in balance.*.md; do
        cat "$file" >>"$output"
        echo "" >>"$output"
    done

    echo "" >>"$output"
fi

# Add features
if ls features.*.md >/dev/null 2>&1; then

    cat "$templateFeatures" >>"$output"
    echo "" >>"$output"

    for file in features.*.md; do
        cat "$file" >>"$output"
        echo "" >>"$output"
    done

    echo "" >>"$output"
fi

# Add graphics changes
if ls graphics.*.md >/dev/null 2>&1; then

    cat "$templateGraphics" >>"$output"
    echo "" >>"$output"

    for file in graphics.*.md; do
        cat "$file" >>"$output"
        echo "" >>"$output"
    done

    echo "" >>"$output"
fi

# Add AI changes
if ls ai.*.md >/dev/null 2>&1; then

    cat "$templateAI" >>"$output"
    echo "" >>"$output"

    for file in ai.*.md; do
        cat "$file" >>"$output"
        echo "" >>"$output"
    done

    echo "" >>"$output"
fi

# Add other changes
if ls other.*.md >/dev/null 2>&1; then

    cat "$templateOther" >>"$output"
    echo "" >>"$output"

    for file in other.*.md; do
        cat "$file" >>"$output"
        echo "" >>"$output"
    done

    echo "" >>"$output"
fi

# Add the initial header
cat "$templateFooter" >>"$output"

#endregion
