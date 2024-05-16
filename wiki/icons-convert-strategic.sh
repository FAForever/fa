#!/bin/bash

#******************************************************************************************************
#** Copyright (c) 2024 FAForever
#**
#** Permission is hereby granted, free of charge, to any person obtaining a copy
#** of this software and associated documentation files (the "Software"), to deal
#** in the Software without restriction, including without limitation the rights
#** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#** copies of the Software, and to permit persons to whom the Software is
#** furnished to do so, subject to the following conditions:
#**
#** The above copyright notice and this permission notice shall be included in all
#** copies or substantial portions of the Software.
#**
#** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#** SOFTWARE.
#******************************************************************************************************

# Process named arguments
while getopts ":w:f:" opt; do
    case $opt in
        w) wiki_dir="$OPTARG";;
        f) fa_dir="$OPTARG";;
        \?) echo "Invalid option: -$OPTARG" >&2
            exit 1;;
        :) echo "Option -$OPTARG requires an argument." >&2
            exit 1;;
    esac
done

if [ -d "$wiki_dir/generated" ]; then
    if [ -d "$wiki_dir/generated/strategicicons" ]; then
        rm -rf "$wiki_dir/generated/strategicicons"
    fi
else
    mkdir "$wiki_dir/generated"
fi

mkdir "$wiki_dir/generated/strategicicons"

mogrify -path "$wiki_dir/generated/strategicicons" -format png "$fa_dir/textures/ui/common/game/strategicicons/*.dds"
