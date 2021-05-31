#!/bin/bash

# Program description: replaces each file that has said entry with '_' 
# Program arguments: 
#  - $1: expression to search and replace (destroy)


# About making bash functions: https://devqa.io/create-call-bash-functions/
# About the sed functionality: https://linuxhint.com/bash_sed_examples/

# $1 = regular expression for files
# $2 = pattern to dismiss
replace(){
    for fname in $1 ; do echo "$fname" ; done
    for fname in $1 ; do mv "$fname" "$(echo "$fname" | sed $2)" ; done
}

replace "*$1*" "s/$1/_/"