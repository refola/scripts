#!/bin/bash

# Output the location of a command. Useful for scripts that need to
# access their location.

if [ -z "$1" ]
then
    echo "Usage: \"$(cmpath "$0")\" path"
    echo "Outputs the path's location after resolving symlinks and such."
    exit 1
else
    echo -n "$(dirname "$(cmpath "$1")")"
fi
