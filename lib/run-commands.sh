#!/bin/bash
# Generic command-running script, intended for running several
# commands at once or for cases where a command is required without
# supporting Bash syntax.

default_name="run-commands"
name="$(basename "${0/%.sh/}")" # get only the name of the script

usage="Please symlink your script to here ($(cmpath "$0")) and set the
commands to run via configs instead of running $default_name
directly."

if [ "$name" = "$default_name" ]; then
    echo "$usage" >&2
    exit 1
fi

check-config() {
    get-config "$name/$1" -what-do "$2" >/dev/null || exit 1
}

# Ensure that it's been configured (interactively) before use.
check-config description "description of what's ran for $name"
check-config commands "commands to run for $name"

# Just source the file. What could possibly go wrong?
. "$(get-config "$name/commands" -path)"
