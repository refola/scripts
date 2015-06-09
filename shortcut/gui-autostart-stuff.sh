#!/bin/bash

echo "This script is intended to auto-launch a bunch of programs that
are wanted for a GUI computing session. If you are seeing this
message, then you're doing it wrong. See your desktop environment's
documentation for how to do it right."

IFS=$'\n' # Separate commands by newlines.
commands=( $(get-config "gui-autostart-stuff/commands" \
                        "list of commands to start") )

for cmd in "${commands[@]}"
do
    # Separate command and arguments with spaces.
    IFS=' '
    $cmd
done
