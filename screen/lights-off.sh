#!/bin/bash

this="$(basename "$0")"
that="${this/off/on}"

if [ "$this" = "$that" ]
then
    echo "Error: This script's name '$this' does not contain the string 'off'." >&2
    echo "The lights-on and lights-off scripts must have corresponding names." >&2
    exit 1
fi

pids="$(pidof -x "$that")" # Not portable, but neither is lights-on
if [ "$?" = "0" ]
then
    for pid in $pids
    do
        echo "Stopping $that with pid=$pid."
        kill $pid
    done
else
    echo "Error: No process with name '$that'." >&2
    exit 1
fi
