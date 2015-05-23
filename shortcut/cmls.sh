#!/bin/bash
# List details of the file referred to by a command.

if [ -z "$1" ]
then
    echo "Usage: \"$(basename "$(readlink -f "$0")")\" command"
    echo "Runs ls -l on a command's file."
    exit 1
else
    # get command's path and run ls on it
    ls -l $(cmpath $1)
fi
