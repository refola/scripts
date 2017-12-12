#!/bin/bash
## cmss.sh
# Run Shellcheck on the given commands.

usage="Usage: $(cmpath "$0") command [...]
Run Shellcheck on one or more commands."

if [ -z "$1" ]; then
    echo "$usage" >&2
    exit 1
else
    for x in "$@"; do
        cmcd "$x"
        shellcheck -x "$(cmpath "$x")"
    done
fi
