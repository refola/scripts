#!/bin/sh
## log.sh
# Log arguments to a time-stamped file.

usage="log name [text [...]]

When passed a name, log outputs the log of that name.

When passed a name and text, log timestamps the text and appends the
result to the log of given name.

On first use, log prompts for a location in which to store the logs."

# Args are mandatory.
if [ -z "$*" ]; then
    echo "$usage"
    # Show list of saved variable sets
    log_loc="$(get-config log/location)" || exit 1
    mkdir -p "$log_loc" # in case of new configuration
    echo "List of current log names:"
    ls -m "$log_loc"

    exit 1
fi

location="$(get-config "log/location" -what-do "directory to store logs in" || exit 1)/$1"
mkdir -p "$(dirname "$location")"
shift

if [ -z "$*" ]; then
    cat "$location"
else
    echo "$(date --iso-8601=seconds): $*" >> "$location"
fi
