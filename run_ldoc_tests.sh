#!/bin/bash

if [ -z "$TRAVIS_BUILD_DIR" ]; then
  TRAVIS_BUILD_DIR=$PWD  # Dev-Mode
fi

echo "Before install .." 
HOME="$TRAVIS_BUILD_DIR/.." 
echo "HOME="$HOME 
echo "TRAVIS_BUILD_DIR="$TRAVIS_BUILD_DIR

cd $HOME

# ################################################################
# Setting up LDoc

sudo apt-get install tree # Just to debug LDoc output 
mkdir ldoc-build # ldoc result

# Download & install luarocks

if [ ! -f luarocks-2.4.1.tar.gz ]; then
  echo "File not found!"
  wget https://luarocks.org/releases/luarocks-2.4.1.tar.gz
fi

tar zxpf luarocks-2.4.1.tar.gz

cd luarocks-2.4.1 # We're now in ~/luarocks-2.4.1

./configure; sudo make bootstrap

# Now we can install luasocket, luafilesystem and ldoc
sudo luarocks install luasocket
sudo luarocks install luafilesystem
sudo luarocks install ldoc

cd $HOME

ldoc -a -c fa/.ldoc/.cfg/config.ld -s fa/.ldoc/.cfg -d ldoc-build/ fa/

tree ldoc-build/ # Show me what you've got!

