#!/bin/bash

this="$(basename "$0")"
that="${this/off/on}"

if [ "$this" = "$that" ]
then
    echo "Error: This script's name '$this' does not contain the string 'off'." >&2
    echo "The lights-on and lights-off scripts must have corresponding names." >&2
    exit 1
fi

# TODO: check if it's running before trying to kill it.
echo "Stopping '$that'."
if ! killall --user "$USER" "$that" 2>/dev/null
then
    echo "Error: Could not kill '$that'." >&2
    exit 1
fi
