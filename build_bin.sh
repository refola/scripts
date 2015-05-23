#!/bin/bash

# rebuild_bin.sh

# Go through all the scripts and make shortcuts in ./bin, stripping
# the .sh.

# Output control
if [ "$1" = "-v" ]
then
    VERBOSE="true"
fi
# Usage: msg message
# If in verbose mode, echo what's passed. Otherwise don't.
msg () {
    if [ "$VERBOSE" = "true" ]
    then
	echo "$@"
    fi
}
msg "VERBOSE=$VERBOSE"

# Directories to skip, via regex patterns that will be
# concatenated. For example, "\." will skip all items that have a
# literal dot (".") in their name.
SKIP_DIRS="
\.
bash_custom
bin
example
fun
sourced
"

# Build the skip pattern by converting newlines to pipes and removing
# the outer-most pipes to avoid matching the empty string that's
# contained within everything we don't want to skip.
SKIP_PATTERN="$(echo -n "$SKIP_DIRS" | tr $'\n' '|' | cut -c2- | rev | cut -c2- | rev)"

# Where we are: the place that everything's relative to
HERE="$(dirname "$(readlink -f "$0")")"
msg "We are at $HERE."

# Where to make the symlinks
BIN="$HERE/bin"
msg "We are making links at $BIN."

# Usage: nuke
# Removes everything in $BIN and remakes the directory.
nuke () {
    msg "Nuking $BIN."
    rm -r "$BIN"
    msg "Making new $BIN."
    mkdir "$BIN"
}

# Usage: target path
# Outputs how the given script should be targetted in a link.
target () {
    echo -n "$1"
}

# Usage: name path
# Outputs how a link to the given script path should be named.
name () {
    echo -n "$BIN/$(basename "$1" | rev | cut -c4- | rev)"
}

# Usage: process item [depth]
# Recursively adds links to scripts in directory to $HERE/bin.
process() {
    if [ -d "$1" ]
    then
	msg "Processing $1 recursively."
	for item in $(ls -A "$1" | grep -v '~')
	do
	    process "$1/$item"
	done
	# If $1 is a regular file, and $1 is executable, and $1 isn't a link
    elif [ -f "$1" -a -x "$1" -a ! -h "$1" ]
    then
	local TARGET="$(target "$1")"
	local NAME="$(name "$1")"
	msg "$NAME -> $TARGET"
	ln -s "$TARGET" "$NAME"
    else
	msg "Cannot process $1."
    fi
}

main() {
    echo "Rebuilding $BIN. (Run this script with '-v' for verbose mode.)"
    nuke
    for item in $(ls -A "$HERE" | grep -E -v "$SKIP_PATTERN")
    do
	local ITEM="$HERE/$item"
	if [ -d "$ITEM" ]
	then
	    process "$ITEM"
	else
	    msg "Not processing $ITEM"
	fi
    done
    echo "Done."
}

main

