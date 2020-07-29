#!/bin/bash
## hist.sh
# Search through custom command history folder for commands matching
# given pattern, displaying last several results.

count=25 # default
usage="$(basename "$0") [--] regex [count]
$(basename "$0") [args ...]

Searches files in ${HISTARCHIVE/$HOME/\~} for given regex, returning the
last 'count' (default $count) lines.

Special args:
all        When passed as a count, show all results.
--         Force the next arg to be the regex (e.g., to search for '--raw')
--grep -g  Only do the search, skipping filtration. Accepts additional
           grep args.
--raw  -r  Switch to raw grep mode without even the default
           '-Ehe'. Further args are passed to grep as-is.
"

files=("$HISTARCHIVE"/*) # custom history location used by $PROMPT_COMMAND
declare -a args=(--extended-regexp --no-filename) # grep arguments (default, before adding files list)
filter=true # if the filter applies

# arg parsing
case "$1" in
    "") # show usage when no args given
        echo "$usage"
        exit 1 ;;
    --)
        shift
        args+=(--regexp="$1") ;;
    --grep)
        shift
        filter=""
        args+=("$@") ;;
    --raw)
        shift
        filter=""
        args=("$@") ;;
    *) # just regex, no fancy args
        args+=(--regexp="$1") ;;
esac

args+=("${files[@]}")
if [ -n "$filter" ]; then
    count="${2-$count}" # filter still on ⇒ $2 is count xor absent
    count="${count/all/+1}" # convert non-numeric count to arg for 'tail'
    grep "${args[@]}" | uniq | tail -n "$count"
else
    grep "${args[@]}"
fi
