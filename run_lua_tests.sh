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
  check_file "$file"
  (( files_checked++ ))
done < <(find . -type d \( -path ./testmaps -o -path ./engine \) -prune -false -o -name '*.lua' -o -name '*.bp')

if [[ $had_error != 0 ]]; then
  echo "Syntax errors detected."
else
  echo "Syntax OK."
fi

echo "Checked $files_checked files"

exit $had_error
