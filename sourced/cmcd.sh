#!/bin/bash
# Change the the folder containing a command's executable file.
# NOTE: This must be sourced (e.g., in your .bashrc) in order to work!

# Usage: cmcd command
# Changes working directory to location of command.
cmcd() {
	if [ -z "$1" ]
	then
		echo "Usage: cmcd command"
		echo "Changes the working directory to command's location."
	else
		# With proper quoting and subshell result-getting, get
		# location of command from $PATH, convert all involved
		# symlinks into canonical paths, and take the directory name.
		cd "$(dirname "$(readlink -f "$(which "$1")")")"
	fi
}
