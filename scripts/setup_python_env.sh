#!/bin/bash
set -euo pipefail

# For debug
# set -x

VENV_NAME=".venv"
PYTHON_REQUIREMENTS="requirements.txt"
SCRIPT_PATH=$(realpath "${BASH_SOURCE[0]}")

SCRIPT_DIR=$(dirname "${SCRIPT_PATH}")
VENV_PATH="${SCRIPT_DIR}/${VENV_NAME}"

# Check if the script is being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This script must be sourced, not executed."
    echo "Please run: source ${BASH_SOURCE[0]}"
    exit 1
fi

# Create venv if it doesn't exist
if ! [ -f "$VENV_PATH" ]; then
    python3 -m venv "$VENV_PATH"
fi

# shellcheck disable=SC1091
source "${VENV_PATH}/bin/activate"

# Update existing or install missing packages
python3 -m pip install --upgrade pip
python3 -m pip install --requirement "${SCRIPT_DIR}/${PYTHON_REQUIREMENTS}"
