#!/bin/bash

# Simple lua code syntax checker using https://github.com/FAForever/lua-lang
# Assumes that FAF lua is installed as `luac`

had_error=0
files_checked=0

check_file() {
  file="$1"

  output="$(luac -p "$file" 2>&1 \
    | sed "s:/dev/fd/[0-9]\+:$file:g")"

  if [[ $output != "" ]]; then
    echo "$output" > /dev/fd/2
    had_error=1
  fi
}

# Some files have spaces in their name so we use this syntax to make sure the
# output from `find` is split by line.
while read file; do
  # file contains table pre-allocation synax ( {&1&4} ) that is not supported at the moment
  if [ "$file" != "./lua/lazyvar.lua" ]; then
    if [ "$file" != "./.vscode/fa-plugin.lua" ]; then
      if [ "$file" != "./lua/system/class.lua" ]; then
        if [ "$file" != "./lua/sim/NavGenerator.lua" ]; then
          check_file "$file"
          (( files_checked++ ))
        fi
      fi
    fi
  fi
done < <(find . -type d \( -path ./testmaps -o -path ./engine \) -prune -false -o -name '*.lua' -o -name '*.bp')

echo "Checked $files_checked files"

if [[ $had_error != 0 ]]; then
  echo "Syntax errors detected."
  exit $had_error
else
  echo "Syntax OK."
fi
