#!/bin/bash

# Output the actual path of a command, resolving symlinks.

if [ -z "$1" ]
then
    echo "Usage: \"$($0 "$0")\" path"
    echo "Outputs the path's location after resolving symlinks."
    exit 1
else
    path="$(which -- "$1")"
    if [ "$?" != "0" ]
    then
        exit 1
    fi
    real="$(readlink -f "$path")"
    if [ "$?" != "0" ]
    then
        exit 1
    fi
    # get command's path and convert symlinks into canonical paths
    echo "$real"
fi
