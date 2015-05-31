#!/bin/bash

# NOTE: This must be sourced order to work!

if [ -z "$1" ]
then
    if [ "$0" = "/bin/bash" ] # If this script is sourced as intended,
    then
	CMD="$(cmpath cmcd)"  # then get the command's path via cmpath,
    else
	CMD="$0"              # Otherwise just use $0.
    fi
    echo "Usage: . $CMD command"
    echo "Changes the working directory to command's location."
else
    # Get command's path, take directory name,
    # and move to there.
    cd "$(dirname "$(cmpath "$1")")"
fi
