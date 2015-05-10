#!/bin/bash
# Change the the folder containing a command's executable file.
# NOTE: This must be sourced (e.g., in your .bashrc) in order to work!
# After sourcing, run it like "cmdcd command".

# Usage: cmdcd command
# Changes working directory to location of command.
cmdcd() {
	if [ -z "$1" ]
	then
		echo "Usage: $(basename "$(readlink -f "$0")")" command
		echo "Changes the working directory to command's location."
		exit 1
	fi

	# With proper quoting and subshell result-getting, get
	# location of command from $PATH, convert all involved
	# symlinks into canonical paths, and take the directory name.
	cd "$(dirname "$(readlink -f "$(which "$1")")")"
}
