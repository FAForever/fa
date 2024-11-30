# Setting Up Python Environment

This directory contains Python scripts that require specific dependencies to be installed. Follow the instructions below to set up the environment and run the scripts.

## Prerequisites

- At least Python 3.8
- pip (Python's package installer)
- python3-venv (Linux only)


## Setting Up the Environment

```bash
# Create a Virtual Environment
python3 -m venv .venv

# Activate the Virtual Environment
# On Windows
.\.venv\Scripts\activate
# On macOS/Linux
source .venv/bin/activate

# Install Dependencies
pip install -r requirements.txt

# Run the script
python script_name.py

# Deactivate the Virtual Environment
deactivate
