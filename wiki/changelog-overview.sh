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

if [ ! -d "wiki/generated" ]; then
    mkdir "wiki/generated"
fi

if [ ! -d "wiki/generated/changelogs" ]; then
    mkdir "wiki/generated/changelogs"
fi

# HTML file to write table
output="wiki/generated/patchnotes-overview.md"

# Start HTML file
echo "<html><head><title>Patchnotes</title></head><body>" >"$output"
echo "<table border='1'>" >>"$output"
echo "<tr><th>File Name</th></tr>" >>"$output"

# List files and create HTML table
for file in ./wiki/generated/changelogs/[0-9]?*.md; do
    if [ -f "$file" ]; then
        file_size=$(stat -c %s "$file")
        file_name=$(basename "$file")
        file_name_no_ex="${file_name%.*}"
        echo "<tr><td><a href="changelog/$file_name_no_ex">$file_name</a></td></tr>" >>"$output"
        echo "Processed: $file_name"
    fi
done

# End HTML file
echo "</table></body></html>" >>"$output"

mv $output "wiki/generated/changelogs/patchnotes-overview.md"