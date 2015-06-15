#!/bin/bash

echo "This script is intended to auto-launch a bunch of programs when
stopping a GUI computing session. If you are seeing this message, then
you're doing it wrong. See your desktop environment's documentation
for how to do it right."

# The IFS and extra parentheses turn $folders into an array.
IFS=$'\n'
commands=( $(get-config "on-gui-shutdown/commands" \
                        -what-do "list of commands to run on shutdown" \
                        -var-rep ) ) || exit 1

for cmd in "${commands[@]}"
do
    # Show command being ran, in case this is being used in a debug
    # context. Output is ignored anyway in the normal case.
    echo "Command: $cmd"
    # Actually run the command. Using eval seems cleaner than trying
    # to run $cmd, especially if it's complex.
    eval "$cmd"
done
