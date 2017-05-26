#!/bin/sh
## secho.sh
# Do what is naively intended by the most common `sudo echo...` commands.

usage="Usage: secho text file

This is a shortcut for 'echo text | sudo tee file >/dev/null', and
named after the 'sudo echo' in the (wrong) 'sudo echo text > file'."

if [ -z "$2" ] || [ -n "$3" ]; then
    echo "$usage"
    exit 1
else
    echo "$1" | sudo tee "$2" >/dev/null
fi
