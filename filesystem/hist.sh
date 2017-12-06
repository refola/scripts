#!/bin/sh
## hist.sh
# Searches through custom command history folder for commands matching
# given pattern, displaying last several results.

dir="$HISTARCHIVE" # Custom history location used by $PROMPT_COMMAND
count="${2-25}" # How many entries to show
usage="Usage: $(basename "$0") regex [count]

Searches files in $dir for given regex, returning the
last count (default $count) lines. Count can be 'all' to display all
matching history items."
[ -z "$1" ] && echo "$usage" && exit 1 # Check for input
count="$(echo "$count" | sed 's/^all$/+1/g')" # Make 'all' show all.
grep -Ehe "$1" "$dir"/* | uniq | tail -n "$count" # Do the search
