#!/bin/bash
# scrub.sh
# Run btrfs scrub for pre-determined locations and save output to
# date-based filenames.

PLACE="/home/mark/doc/text/tech/hardware/core-plus/btrfs-info"
DATE="$(date --utc +%F)" # Get current UTC date

# This should be fastest-to-slowest-ordered list of scrubs to run, in
# the "name location" format.
DISKS="
internal /
external /run/media/mark/OT4P/
"

# Usage: scrub name location
# Runs btrfs scrub on location and saves results to file based on name.
scrubit() {
	local NAME="$1"
	local LOCATION="$2"
	local FILE="${PLACE}/${DATE}_scrub_${NAME}"
	local DISP="$NAME at $LOCATION"
	echo "Starting btrfs scrub for $DISP."
	sudo btrfs scrub start -B -d "$LOCATION" > "$FILE"
	echo
	echo "Scrub finished for $DISP. Results are as follows:"
	cat "$FILE"
}

# Usage: tupleloop tuple-list function
# Loops through all space-separated tuples in a newline-separated
# list, running the given function with the tuple's contents as
# arguments. How to use IFS and set gotten from
# https://stackoverflow.com/questions/9713104/loop-over-tuples-in-bash
tupleloop() {
	local N=$'\n' # Tidiest newline per
		      # https://stackoverflow.com/questions/9139401/trying-to-embed-newline-in-a-variable-in-bash
	local TUPLES="$1"
	local FUNC="$2"
	local IFS="$N"
	for PAIR in $TUPLES
	do
		local IFS=" "
		set "$PAIR"
		$FUNC $* # Don't change to "$@" because it breaks $FUNC seeing multiple args.
	done
}

# Usage: tuplelooploop tuples function1 [function2 [...]]
# Runs tupleloop on given tuples string with given function(s).
tuplelooploop() {
	local TUPLES="$1"
	shift
	for FUNC in "$@"
	do
		tupleloop "$TUPLES" "$FUNC"
	done
}

# Usage: setLASTifdir ignored dir
# Sets $LAST to dir if dir is a directory.
setLASTifdir() {
	if [ -d "$2" ]
	then
		LAST="$2"
	fi
}

# Usage: scrubwrap name path
# Runs btrfs scrub, backgrounding if path isn't equal to $LAST.
scrubwrap() {
	if [ "$2" = "$LAST" ]
	then
		scrubit "$1" "$2"
	elif [ -d "$2" ]
	then
		scrubit "$1" "$2" &
	fi
}

# Usage: main
# Does the script's main purpose.
main() {
	# Before starting, make sure that sudo is freshly updated.
	echo "Entering sudo mode."
	sudo -v

	# Prioritize scrubs and then start them, fastest first,
	# backgrounding all but the slowest.
	tuplelooploop "$DISKS" setLASTifdir scrubwrap
}

# Usage: myecho [arg1 [arg2 [...]]]
# Echos arguments, prefixing each with its number.
myecho() {
	local IFS=$'\n'
	for i in $(seq $#)
	do
		echo -n "$i:$1 "
		shift
	done
	echo
}

# Usage: testit
# Tests the tupleloop and tuplelooploop functions that complicate this
# script via Bash features with which I was previously unfamiliar.
testit() {
	# Test that tupleloop works.
	for FUNC in echo myecho setLASTifdir
	do
		echo "Running tupleloop on DISKS with $FUNC."
		tupleloop "$DISKS" $FUNC
	done
	echo "Last path is $LAST."
}

#testit
main
