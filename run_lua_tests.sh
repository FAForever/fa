#!/bin/bash

# Ubuntu has luac5.2 instead
[ -z "$LUAC" ] && LUAC="luac"


echo -en 'travis_fold:start:Start Migration Base Test\\r'
echo '1'
echo '2'
echo '3'
echo -en 'travis_fold:end:End Migration Base Test\\r'

echo -e 'travis_fold:start:Start Migration Base Test\\r'
echo '1'
echo '2'
echo '3'
echo -e 'travis_fold:end:Start Migration Base Test\\r'

echo -e 'travis_fold:start:Start Migration Base Test'
echo '1'
echo '2'
echo '3'
echo -e 'travis_fold:end:Start Migration Base Test'

echo 'travis_fold:start:Start Migration Base Test'
echo '1'
echo '2'
echo '3'
echo 'travis_fold:end:Start Migration Base Test'



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

for file in `find . -name '*.lua' -o -name '*.bp'`; do
  check_file "$file"
done

if [[ $had_error != 0 ]]; then
  echo "Syntax errors detected."
else
  echo "Syntax OK."
fi

exit $had_error
