#!/bin/bash

# Simple lua code syntax checker using https://github.com/FAForever/lua-lang
# Assumes that FAF lua is installed as `lua`

had_error=0

run_test() {
  file="$1"

  output="$(lua "$file" 2>&1 |
    sed "s:/dev/fd/[0-9]\+:$file:g")"

  if [[ $output != "" ]]; then
    echo "$output" >/dev/fd/2
    if [[ "$output" == *"FAIL"* || "$output" == *"stack traceback"* ]]; then
      had_error=1
    fi
  fi
}

# make sure the test files run in the tests directory
pushd tests >/dev/null

run_test "test_colors.lua"
run_test "test_utils.lua"

popd >/dev/null

if [[ $had_error != 0 ]]; then
  echo "Tests returned errors."
  exit $had_error
else
  echo "Tests OK."
fi
