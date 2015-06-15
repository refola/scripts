#!/bin/bash

echo "This script is intended to auto-launch a bunch of programs when
starting a GUI computing session. If you are seeing this message, then
you're doing it wrong. See your desktop environment's documentation
for how to do it right."

IFS=$'\n' # Separate commands by newlines.
commands=( $(get-config "on-gui-startup/commands" \
                        -what-do "list of commands to run on startup" \
                        -var-rep ) )

for cmd in "${commands[@]}"
do
    # Show command being ran, in case this is being used in a debug
    # context. Output is ignored anyway in the normal case.
    echo "Command: $cmd"
    # Actually run the command. Using eval seems cleaner than trying
    # to run $cmd, especially if it's complex.
    eval "$cmd"
done
