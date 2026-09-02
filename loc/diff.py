#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Compare two Lua key-value files and generate the set difference of keys,
including the corresponding values from each file.

Created by HaoJun0823 on 2026-08-26.

Usage:
    python compare_lua_keys_with_values.py file1.lua file2.lua
    python compare_lua_keys_with_values.py ID1 ID2   # automatically appends /strings_db.lua

Output:
    only_in_<basename1>.txt   # keys present in file1 but not in file2, with values from file1
    only_in_<basename2>.txt   # keys present in file2 but not in file1, with values from file2
"""

import re
import sys
from pathlib import Path

def resolve_path(arg):
    if arg.lower().endswith('.lua'):
        return Path(arg)
    else:
        return Path(arg) / 'strings_db.lua'

def extract_keys_and_values(filepath):
    """Extract all key names and their corresponding values (right-hand side strings) from a .lua file."""
    data = {}
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    # Match lines like KEY = "value" or KEY = 'value'
    pattern = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(["\'].*?["\'])', re.MULTILINE)
    for match in pattern.finditer(content):
        key = match.group(1)
        value = match.group(2)  # preserve quotes
        data[key] = value
    return data

def main():
    if len(sys.argv) != 3:
        print("Usage:")
        print("   python compare_lua_keys_with_values.py <file1.lua> <file2.lua>")
        print("   python compare_lua_keys_with_values.py <ID1> <ID2>")
        sys.exit(1)

    path1 = resolve_path(sys.argv[1])
    path2 = resolve_path(sys.argv[2])

    if not path1.exists():
        print(f"Error: file {path1} does not exist")
        sys.exit(1)
    if not path2.exists():
        print(f"Error: file {path2} does not exist")
        sys.exit(1)

    print(f"Parsing {path1} ...")
    dict1 = extract_keys_and_values(path1)
    print(f"Found {len(dict1)} keys")

    print(f"Parsing {path2} ...")
    dict2 = extract_keys_and_values(path2)
    print(f"Found {len(dict2)} keys")

    keys1 = set(dict1.keys())
    keys2 = set(dict2.keys())

    only_in_1 = keys1 - keys2
    only_in_2 = keys2 - keys1

    base1 = Path(sys.argv[1]).stem
    base2 = Path(sys.argv[2]).stem
    out1 = Path.cwd() / f"only_in_{base1}.txt"
    out2 = Path.cwd() / f"only_in_{base2}.txt"

    with open(out1, 'w', encoding='utf-8') as f:
        for key in sorted(only_in_1):
            f.write(f'{key} = {dict1[key]}\n')
    with open(out2, 'w', encoding='utf-8') as f:
        for key in sorted(only_in_2):
            f.write(f'{key} = {dict2[key]}\n')

    print(f"Keys only in {path1}: {len(only_in_1)} -> saved to {out1}")
    print(f"Keys only in {path2}: {len(only_in_2)} -> saved to {out2}")

if __name__ == "__main__":
    main()