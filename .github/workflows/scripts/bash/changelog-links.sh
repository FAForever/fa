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

# Function to display usage information
usage() {
    echo "Usage: $0 <folder_name> <org_name> <repository_name> <base_url>"
    exit 1
}

# Check if the correct number of arguments is provided
if [ $# -ne 4 ]; then
    usage
fi

# Assign input arguments to variables
FOLDER_NAME=$1
ORG_NAME=$2
REPO_NAME=$3
BASE_HOSTNAME=$4

# Verify the folder exists
if [ ! -d "$FOLDER_NAME" ]; then
    echo "Error: Folder '$FOLDER_NAME' does not exist."
    exit 1
fi

# Loop through all files in the folder and execute a command
for FILE in "$FOLDER_NAME"/*; 
do
    if [[ -f "$FILE" && "$FILE" == *.md ]]; then
        # Replace this with your actual command
        echo "Executing command on file: $FILE"
        # Example command
        TMP_FILE=$(mktemp)
        sed -E 's/#([0-9]{4,5})/[#\1](https:\/\/'"$BASE_HOSTNAME"'\/'"$ORG_NAME"'\/'"$REPO_NAME"'\/pull\/\1)/g' "$FILE" > "$TMP_FILE"
        mv "$TMP_FILE" "$FILE"
        echo "File $FILE has been updated."
    fi
done

echo "Script execution completed."