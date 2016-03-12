#!/bin/bash
# List details of a command's file.

if [ "$#" = "0" ]; then
    # Assumes a function sources this
    echo "Usage: cmls command ..."
    echo
    echo "Runs ls -l on given commands' files."
    exit 1
else
    local commands
    while [ "$#" != "0" ]; do
        # get command's path and run ls on it
        commands+=("$(cmpath "$1")")
        shift
    done
    ls -l "${commands[@]}"
fi
