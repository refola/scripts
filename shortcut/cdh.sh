#!/bin/bash

if [ -z "$1" ]
then
    if [ "$PWD" = "$H" ]
    then
        # This assumes that cdh is a function that sources this script.
        echo "Usage: cdh [path]"
        echo "Changes the working directory to the given path"
        echo "and sets \$H to the path. Otherwise changes the"
        echo "working directory to \$H."
    else
        cd "$H"
    fi
else
    # Change to the given path and set $H to the path.
    cd "$1"
    export H="$PWD" # $PWD gets rid of relative paths.
fi
