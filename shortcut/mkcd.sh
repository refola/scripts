#!/bin/bash

# This assumes that mkcd is a function that sources this script.
local usage="Usage: mkcd possibly-relative/path/to/folder

Makes the given folder if it doesn't already exist and changes the
working directory to it. This is equivalent to calling 'mkdir -p path'
and then 'cd path'."

if [ "$#" != "1" ]
then
    echo "$usage"
else
    mkdir -p "$1"
    cd "$1"
fi
