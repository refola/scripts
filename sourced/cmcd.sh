#!/bin/bash

# NOTE: This must be sourced (e.g., in your .bashrc) in order to work!

cmcd() {
	if [ -z "$1" ]
	then
		echo "Usage: cmcd command"
		echo "Changes the working directory to command's location."
	else
		# Convert any symlinks in path, take directory name,
		# and move to there.
		cd "$(dirname "$(cmpath "$1")")"
	fi
}
