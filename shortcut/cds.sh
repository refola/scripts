#!/bin/bash
## cds.sh
# Save $PWD and $H.

if [ -z "$1" ]; then
    echo "Usage: cds name"
    echo "Saves \$PWD and \$H with given name, to be restored by cdl."
else
    # Get place to save variables to.
    path="$(get-config "var-save/$*" -path)"
    # Save them.
    mkdir -p "$path"
    echo "$PWD" > "$path/PWD"
    echo "$H" > "$path/H"
fi
