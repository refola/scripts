#!/bin/bash
## pidsof.sh
# Clone the Linux pidof command in a cross-*nix way.

usage="Usage: $(basename "$0") program_name

Searches for processes corresponding to program_name and outputs the
PIDs of any results."

if [ -z "$1" ]
then
    echo "$usage" >&2
    exit 1
else
    pids="$(ps --no-headers -o pid -C "$1")"
    if [ "$?" = "0" ]
    then
        echo "$pids"
        exit 0
    else
        echo "No process found of name $1." >&2
        exit 1
    fi
fi
