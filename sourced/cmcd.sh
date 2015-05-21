#!/bin/bash

# NOTE: This must be sourced (e.g., in your .bashrc) in order to work!

cmcd() {
	if [ -z "$1" ]
	then
		echo "Usage: cmcd command"
		echo "Changes the working directory to command's location."
	else
		# Find and source the actual command, passing the
		# argument to it.
		. "$(cmpath cmcd)" "$1"
	fi
}
