#!/bin/bash

# Restore $PWD and $H as saved by cds.

if [ -z "$1" ]
then
    # This assumes that cds is a function that sources this script.
    echo "Usage: cdl name"
    echo "Restores \$PWD and \$H with given name, as saved by cdl."
    # Show list of saved variable sets
    path="$(get-config "var-save" -path)"
    echo "List of saved path names:"
    ls -m "$path"
else
    # Get place to load variables from.
    path="$(get-config "var-save/$1" -path)"
    # Load them implicitly with appropriate commands.
    cdh "$(cat "$path/H")"
    cd "$(cat "$path/PWD")"
fi
