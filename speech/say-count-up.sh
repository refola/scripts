#!/usr/bin/env bash

usage="Usage: $(basename "$0") to [by]

Counts to 'to' in increments of 'by'."

if [ -z "$1" ]; then
    say "$usage"
    exit 1
else
    to="$1"
    by="${2-1}"
    for ((n="$by"; n<="$to"; n+="$by")); do
        say "$n"
    done
fi
