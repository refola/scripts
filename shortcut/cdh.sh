#!/bin/bash

if [ -z "$1" ]
then
    # This assumes that cdh is a function that sources this script.
    echo "Usage: cdh path"
    echo "Changes the working directory to the given path"
    echo "and sets \$H to the path."
else
    # Change to the given path and set $H to the path.
    cd "$1"
    export H="$PWD" # $PWD gets rid of relative paths.
fi
