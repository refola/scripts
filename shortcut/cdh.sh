#!/bin/bash

# NOTE: This must be sourced order to work!

if [ -z "$1" ]
then
    if [ "$0" = "/bin/bash" ] # If this script is sourced as intended,
    then
	CMD="$(cmpath cdh)"   # then get the command's path via cmpath,
    else
	CMD="$0"              # Otherwise just use $0.
    fi
    echo "Usage: . $CMD path"
    echo "Changes the working directory to the given path"
    echo "and sets \$H to the path."
else
    # Change to the given path and set $H to the path.
    cd "$1"
    export H="$PWD" # Use $PWD instead of $1 
fi
