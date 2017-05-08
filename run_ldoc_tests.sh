#!/bin/bash


# ################################################################
# Initializing ..

if [ -z "$TRAVIS_BUILD_DIR" ]; then
  TRAVIS_BUILD_DIR=$PWD  # Dev-Mode
fi

echo "Environment:"
HOME="$TRAVIS_BUILD_DIR/.." 
echo "HOME="$HOME 
echo "TRAVIS_BUILD_DIR="$TRAVIS_BUILD_DIR


# ################################################################
# Setting up LDoc

cd $HOME

# Download, configure and install luarocks

if [ ! -f luarocks-2.4.1.tar.gz ]; then
  echo "File not found!"
  wget https://luarocks.org/releases/luarocks-2.4.1.tar.gz
fi

tar zxpf luarocks-2.4.1.tar.gz

cd luarocks-2.4.1 

./configure; sudo make bootstrap

# With luarocks we can install luasocket, luafilesystem and ldoc
sudo luarocks install luasocket
sudo luarocks install luafilesystem
sudo luarocks install ldoc


# ################################################################
# Running LDoc

cd $HOME

# Let's run LDoc now ..

mkdir ldoc-build # ldoc result

echo "Starting LDoc .."
ldoc_error="ldoc -a -c fa/.ldoc/.cfg/config.ld -s fa/.ldoc/.cfg -d ldoc-build/ fa/"

# Ask LDoc first ..
if [ $ldoc_error ]; then
  echo "LDoc returned with error code: " $ldoc_error
  exit 1
fi

if [ "$(ls -A ldoc-build)" ]; then
  echo "ldoc-build/ appears to be empty. No documentation has been generated?"
  exit 1
fi


# ################################################################
# Deploy documentation

echo "Deploying documentation .."

# From here we can deploy the website
sudo apt-get install tree  # Just to debug LDoc output 
tree ldoc-build/           # Show me what you've got!


echo "All done."
