#!/bin/bash
## hist.sh
# Searches through custom Bash history folder for commands matching
# given pattern, displaying last several results.

DIR="$HISTARCHIVE" # Custom history location used by $PROMPT_COMMAND

COUNT="50" # How many entries to show
if [ ! -z "$2" ]
then
    COUNT="$2"
fi

if [ -z "$1" ]
then
    echo "Usage: `basename $0` regex [count]"
    echo "Searches files in $DIR for given regex, returning the last count (default $COUNT) lines"
    echo "Count can be \"all\" to display all matching history items."
    exit 1
fi

cd "$DIR"
if [ "$COUNT" = "all" ]
then
    cat `ls $DIR` | egrep "$1"
else
    cat `ls $DIR` | egrep "$1" | tail -n $COUNT
fi
