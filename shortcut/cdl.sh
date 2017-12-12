#!/bin/bash
## cdl.sh
# Sourcable script for `cdl()` function.

if [ -z "$1" ]; then
    echo "Usage: cdl name"
    echo "Restores \$PWD and \$H with given name, as saved by cdl."
    # Show list of saved variable sets
    path="$(get-config "var-save" -path)"
    echo "List of saved path names:"
    ls -m "$path"
else
    # Get place to load variables from.
    path="$(get-config "var-save/$*" -path)"
    # Load them implicitly with appropriate commands.
    cdh "$(cat "$path/H")"
    # This is sourced and we don't want to exit the interactive session.
    # shellcheck disable=SC2164
    cd "$(cat "$path/PWD")"
fi
