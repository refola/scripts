#!/bin/bash
# Generic command-running script, intended for running several
# commands at once or for cases where a command is required without
# supporting Bash syntax.

default_name="run-commands"
name="$(basename "${0/%.sh/}")" # get only the name of the script

if [ "$name" = "$default_name" ]; then
    echo "Please symlink your script to here and set the commands to"
    echo "run via configs instead of running $default_name directly."
    exit 1
fi

get() {
    get-config "$name/$1" \
               -what-do "list of commands to run for $name" \
               -var-rep \
               || exit 1
}

echo "$(get description)" || exit 1

# The IFS and extra parentheses turn $commands into an array.
IFS=$'\n'
commands=( get commands ) || exit 1

for cmd in "${commands[@]}"
do
    # Show command being ran, in case this is being used in a debug
    # context. Output is ignored anyway in the normal case.
    echo "Command: $cmd"
    # Actually run the command. Using eval seems cleaner than trying
    # to run $cmd, especially if it's complex.
    eval "$cmd"
done
