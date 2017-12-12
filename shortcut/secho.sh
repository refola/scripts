#!/bin/sh
## secho.sh
# Do what is naively intended by the most common `sudo echo...` commands.

usage="Usage: secho text file [...]

Do what may be naively intended by 'sudo echo text > file'. In
particular, this is a shortcut for:

    echo text | sudo tee file >/dev/null

As a bonus, you can pass additional file names and they will also be
written to with sudo, equivalent to

    echo text | sudo tee file1 | sudo tee file2 [...] >/dev/null"

if [ -z "$2" ]; then
    echo "$usage"
    exit 1
else
    text="$1"
    shift
    for file in "$@"; do
        echo "$text" | sudo tee "$file" >/dev/null
    done
fi
