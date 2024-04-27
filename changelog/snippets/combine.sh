#!/bin/bash

templateAI="sections/template-ai.md"

# Output file name
output="combined.md"

if ! ls *.md >/dev/null 2>&1; then
    echo "No Markdown files found to combine. Are you looking in the wrong directory?"
    exit 1
fi

# Add the initial header

echo "# Game version XYZW (1st of Month, Year)" > "$output"

for file in ai.*.md; do
    # Skip the output file itself
    if [ "$file" != "$output" ]; then
        # Add a separator between files
        echo "### File: $file" >> "$output"
        # Append the content of the current file to the output file
        cat "$file" >> "$output"
        echo "" >> "$output" # Add an empty line between files
    fi
done
