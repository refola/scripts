#!/usr/bin/env bash
## cdl.sh
# Sourcable script for `cdl()` function.

# Get place to load variables from.
path="$(get-config "var-save/$*" -path)"

if [ -z "$1" ] || [ ! -e "$path" ]; then
    echo "Usage: cdl name"
    echo "Restores \$PWD and \$H with given name, as saved by cdl."
    # Show list of saved variable sets
    path="$(get-config "var-save" -path)"
    echo "List of saved path names:"
    ls -m "$path"
else
    # Load them implicitly with appropriate commands.
    cdh "$(cat "$path/H")"
    pcd "$(cat "$path/PWD")"
fi
