#!/bin/bash

# NOTE: This must be sourced order to work!

# This script is really more useful for being called within
# scripts. For interactive shell users, the cmcd command in
# ../sourced/cmcd.sh is more appropriate.

if [ -z "$1" ]
then
	if [ "$0" = "/bin/bash" ]    # If this script is sourced as intended,
	then
		CMD="$(cmpath cmcd)" # then get the command's path via cmpath,
	else
		CMD="$0"             # but otherwise just use $0.
	fi
	echo "Usage: . $CMD command"
	echo "Changes the working directory to command's location."
else
	# Convert any symlinks in path, take directory name,
	# and move to there.
	cd "$(dirname "$(cmpath "$1")")"
fi
