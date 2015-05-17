#!/bin/bash

# Output the location of a command. Useful for scripts that need to
# access their location.

if [ -z "$1" ]
then
	echo "Usage: \"$($0 "$0")\" path"
	echo "Outputs the path's location after resolving symlinks."
	exit 1
else
	# get command's path and convert symlinks into canonical paths
	echo -n "$(readlink -f "$(which $1)")"
fi
