#!/bin/bash
# Edit the file referred to by a command. No more manual, nested,
# "basename of readlink of which" invocations.

CMD="$EDITOR"
if [ "$1" = "-v" ]
then
    CMD="$VISUAL"
    shift
fi

if [ -z "$1" ]
then
    echo "Usage: \"$(basename "$(readlink -f "$0")")\" [-v] command"
    echo "Edits a command."
    echo "Option:"
    echo "    -v    Use $VISUAL instead of $EDITOR."
    exit 1
else
    # convert symlinks into canonical paths and take directory
    # name
    $CMD $(cmpath $1)
fi
