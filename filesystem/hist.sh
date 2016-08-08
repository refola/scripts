#!/bin/bash
## hist.sh
# Searches through custom Bash history folder for commands matching
# given pattern, displaying last several results.

DIR="$HISTARCHIVE" # Custom history location used by $PROMPT_COMMAND

COUNT="25" # How many entries to show
if [ -n "$2" ]
then
    COUNT="$2"
fi

if [ -z "$1" ]
then
    echo "Usage: $(basename "$0") regex [count]"
    echo "Searches files in $DIR for given regex, returning the last count (default $COUNT) lines"
    echo "Count can be \"all\" to display all matching history items."
    exit 1
fi

# Usage: search regex
# Searches history folder for entries matching given regex.
search() {
    local files=( $DIR/* )
    cat "${files[@]}" | egrep "$1" | uniq
}

if [ "$COUNT" = "all" ]
then
    search "$1"
else
    search "$1" | tail -n "$COUNT"
fi
