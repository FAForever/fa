#!/bin/bash

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