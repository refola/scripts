#!/usr/bin/env bash
## cmls.sh
# List details of commands' files.

if [ "$#" = "0" ]; then
    echo "Usage: cmls command [...]"
    echo
    echo "Runs 'ls -l' on given commands' files."
    exit 1
else
    commands=()
    for x in "$@"; do
        commands+=("$(cmpath "$x")")
    done
    ls -l "${commands[@]}"
fi
