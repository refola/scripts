#!/bin/bash

# Output the path of a command. Useful for, e.g., editing the command
# without typing a bunch of recursive subshell stuff.

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
    echo -n "$real"
fi
