#!/bin/bash
## pidsof.sh
# Approximately clone the Linux pidof command in a cross-*nix way.

usage="Usage: $(basename "$0") [--me] program_name

Searches for processes corresponding to program_name and outputs the
PIDs of any results.

If '--me' is passed, then only output PIDs owned by $USER."

maybe-filter() {
    if [ -z "$filter" ]
    then
        echo "$1"
        return 0
    fi

    local pids
    IFS=$'\n'
    for pid in $1
    do
        ps x | egrep " *^$pid " >/dev/null
        if [ "$?" = "0" ]
        then
            pids=("${pids[@]}" "$pid")
        fi
    done
    pids="${pids[*]}"
    if [ -n "$pids" ]
    then
        echo "$pids"
        return 0
    else
        return 1
    fi
}

if [ "$1" = "--me" ]
then
    filter="true"
    shift
fi

if [ -z "$1" ]
then
    echo "$usage" >&2
    exit 1
else
    pids="$(ps --no-headers -o pid -C "$1")"
    pids="$(maybe-filter "$pids")"
    if [ "$?" = "0" ]
    then
        echo "$pids"
        exit 0
    else
        echo "No process found of name $1." >&2
        exit 1
    fi
fi
