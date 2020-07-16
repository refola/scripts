#!/usr/bin/env bash

_usage="$(basename "$0") operation [options]

WARNING: This script is only at prototype level for now....

This script is made for tracking comments made online, enabling easy
retrieval even if the online copy of the comment is lost.

Operations:
find - list all comments matching given name, date, and text constraints
help - print this usage information and exit
load - show the entirety of every comment matching the given constraints
save - save a comment, using options to prepopulate things

Options:
-label - the mutually exclusive category that the comment falls under
        (e.g., the name of the site it's posted under)
-text - the text of the comment, or a search string
-time - when the comment was made
-url - exactly where the comment is posted (can be passed multiple times)
"

# Explicitly unset these variables so we can distinguish null case
# with certainty
unset label text time url

## Usage: bad-arg argument
# Gives a warning message about a bad argument and exits.
bad-arg() {
    echo "Error: Bad argument: '$1'"
    usage 1
}

## Usage: usage exit_code
# Print usage text and exits the program with the given exit code.
usage() {
    echo "$_usage"
    exit "$1"
}

## Usage: set-[variable]
# Checks if the corresponding variable is set and, if unset,
# interactively sets it appropriately.
set-label() {
    if [ -z "${label+x}" ]; then
        read -e -p "Comment label: " label
    fi
}
set-time() {
    if [ -z "${time+x}" ]; then
        read -e -p "Comment time: " -i "$(date -uim)" time
    fi
}
set-urls() {
    if [ "${#url[@]}" = 0 ]; then
        while read -e -p "Append URL? (blank to continue)" line; do
            if [ -z "$line" ]; then
                break
            fi
            url=("${url[@]}" "$line")
        done
    fi
}


# Find and list all comments matching the 
find() {
    
}

## Usage: main "$@"
# sets variables and runs the appropriate function.
main() {
    # make sure we have at least a first arg
    if [ -z "$1" ]; then
        usage 1
    fi
    # get the operation to perform
    case "$1" in
        find|load|save)
            op="$1"
            shift ;;
        help)
            usage 0 ;;
        *)
            usage 1 ;;
    esac
    shift
    # process options-value pairs
    while [ -n "$2" ]; do
        case "$1" in
            -label)
                label="$2" ;;
            -text)
                text="$2" ;;
            -time)
                time="$2" ;;
            -url)
                url=("${url[@]}" "$2") ;;
            *)
                bad-arg "$1" ;;
        esac
        shift 2
    done
    # check for stray argument at end
    if [ -n "$1" ]; then
        bad-arg "$1"
    fi
    # make sure we have a label and time
    set-label
    set-time
    set-urls
    # Finally run whatever was meant to be ran
    "$op"
}

main "$@"
