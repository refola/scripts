#!/usr/bin/env bash
## cmss.sh
# Run Shellcheck on the given commands.

usage="Usage: $(cmpath "$0") command [...]
Run Shellcheck on one or more commands."

if [ -z "$1" ]; then
    echo "$usage" >&2
    exit 1
else
    for x in "$@"; do
        cd "$(cmdir "$x")" ||
            echo "Couldn't 'cd'; paths to sourced scripts may be broken." >&2
        shellcheck -x "$(cmpath "$x")"
    done
fi
