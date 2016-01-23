#!/bin/bash

# Save $PWD and $H's locations with given name for quickly getting
# back in the future.

if [ -z "$1" ]
then
    # This assumes that cds is a function that sources this script.
    echo "Usage: cds name"
    echo "Saves \$PWD and \$H with given name, to be restored by cdl."
else
    # Get place to save variables to.
    path="$(get-config "var-save/$1" -path)"
    mkdir -p "$path"
    # Save them.
    echo "$PWD" > "$path/PWD"
    echo "$H" > "$path/H"
fi
