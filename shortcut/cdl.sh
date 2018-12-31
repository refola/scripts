#!/usr/bin/env bash
## cdl.sh
# Sourcable script for `cdl()` function.

# This is sourced into a function, so "local" is valid.
# shellcheck disable=SC2168
local force path h pwd

if [ "$1" = "-f" ]; then
    force=true
    shift
fi

# Get place to load variables from.
path="$(get-config "var-save/$*" -path)"

if [ -z "$1" ] || [ ! -e "$path" ]; then
    echo "Usage: cdl [-f] name"
    echo "Restores \$PWD and \$H with given name, as saved by cdl."
    echo "With '-f' also makes referenced paths exist before cd'ing."
    # Show list of saved variable sets
    path="$(get-config "var-save" -path)"
    echo "List of saved path names:"
    ls -m "$path"
else
    # Set paths.
    h="$(cat "$path/H")"
    pwd="$(cat "$path/PWD")"
    # Force existence if applicable
    [ -n "$force" ] && mkdir -p "$pwd" "$h"
    # Load paths indirectly via appropriate commands.
    cdh "$h"
    pcd "$pwd"
fi
