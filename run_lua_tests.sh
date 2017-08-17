#!/bin/bash

# Ubuntu has luac5.2 instead
[ -z "$LUAC" ] && LUAC="luac"

# Simple lua code syntax checker using luac

preprocess_gpg_lua() {
  file="$1"
  
  # 1. GPG-style comments and copyright unicode symbol
  # 2. C-style equality
  # 3. C-style continue 

  sed -e "s:^\(\([^\"'#]\|\(\"\|'\)[^\"'#]*\3\)*\)#\(.\|\xa9\)*$:\1:g" \
      -e 's:\!\=:\~\=:g' \
      -e 's:\(\bcontinue\b\):\1\(\):g' \
      "$file"
}

had_error=0
check_file() {
  file="$1"
  
  output="$(luac -p <(preprocess_gpg_lua "$file") 2>&1 \
    | sed "s:/dev/fd/[0-9]\+:$file:g")"

  if [[ $output != "" ]]; then
    echo "$output" > /dev/fd/2
    had_error=1
  fi
}

for file in `find . \( -path ./engine -o -path ./testmaps \) -prune -o -name '*.lua' -o -name '*.bp'`; do
  check_file "$file"
done

if [[ $had_error != 0 ]]; then
  echo "Syntax errors detected."
else
  echo "Syntax OK."
fi

exit $had_error
