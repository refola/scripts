#!/usr/bin/env bash
## cmedit.sh
# Edit the file referred to by a command. No more manual, nested,
# "basename of readlink of which" invocations.

cmd="${EDITOR:-nano}" # Fallback to nano if `$EDITOR` unset
if [ "$1" = "-v" ]; then
    cmd="${VISUAL:-$cmd}" # Only use `$VISUAL` if set
    shift
fi

usage="$(cmpath "$0") [-v] command [...]
Edit one or more commands.
Option:
    -v    Use '$VISUAL' instead of '$EDITOR'."

if [ -z "$1" ]; then
    echo "$usage" >&2
    exit 1
else
    files=()
    for arg in "$@"; do
        path="$(cmpath "$arg")"
        if [ "$?" = "0" ]; then
            files=( "${files[@]}" "$path")
        else
            echo "Command not found: $arg" >&2
            exit 1
        fi
    done
    # Run editor command with all files as arguments.
    "$cmd" "${files[@]}"
fi
