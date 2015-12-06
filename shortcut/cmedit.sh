#!/bin/bash
# Edit the file referred to by a command. No more manual, nested,
# "basename of readlink of which" invocations.

cmd="${EDITOR:-nano}" # Fallback to nano if $EDITOR unset
if [ "$1" = "-v" ]; then
    cmd="${VISUAL:-$cmd}" # Only use $VISUAL if set
    shift
fi

if [ -z "$1" ]; then
    echo "Usage: \"$(basename "$(readlink -f "$0")")\" [-v] command [cmd2 [cmd3 [...]]]"
    echo "Edit one or more commands."
    echo "Option:"
    echo "    -v    Use $VISUAL instead of $EDITOR."
    exit 1
else
    unset files # Is there a cleaner way of ensuring an array variable has no elements?
    for arg in "$@"; do
        path="$(cmpath "$arg")" # cmpath gets the command's path.
        if [ "$?" = "0" ]
        then
            files=( "${files[@]}" "$path")
        else
            echo "Command not found: $arg" >&2
            exit 1
        fi
    done
    # Run editor command with all files as arguments.
    $cmd "${files[@]}"
fi
