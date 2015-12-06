#!/bin/bash

# Set custom stuff for Bash sessions. For the most part this should
# just source other files. To activate, make sure to source this in
# .bashrc.

# "true" or not "true": Should debugging messages be printed?  "true"
# is useful for figuring out which sourced thing is causing errors,
# while not "true" is good for general use when things are working.
DEBUG="false" # not "true"
#DEBUG="true"

# Usage: msg message
# Prints message if DEBUG is true.
msg(){
	if [ "$DEBUG" = "true" ]
	then
		echo "$@"
	fi
}
msg "DEBUG=$DEBUG"

# These variables are required for bootstrapping Bash customizations.
h="/home/$USER" # local version of $H
custom_sourced="$h/sampla/samselpla/scripts/sourced"

# All sorts of custom behaviour locations.
# Note: On openSUSE 13.2 I had to delete grub, libreoffice.sh, and
# ooffice.sh from /etc/bash_completion.d because they caused problems,
# especially grub. At least Bash completion errors partially breaking
# the shell isn't as critical an issue as the bootloader not
# working....
to_source="
/etc/bash_completion
/etc/bash_completion.d
$HOME/.profile
$custom_sourced
"

# Usage: source_them base thing1 [thing2 [...]]
# Source everything in base, maximally recursively.
source_them() {
	local base="$1"
	local IFS=$'\n'
	local x
	for x in $2
	do
		if [ -n "$base" ]
		then
			x="$base/$x"
		fi
		if [ -d "$x" ]
		then
			msg "Getting contents of $x to source"
			source_them "$x" "$(ls "$x")"
		elif [ -f "$x" ]
		then
			msg "Sourcing $x"
			. "$x"
		else
			msg "Cannot source $x"
		fi
	done
}

# Usage: main
# Changes the Bash environment to match all the custom stuff in other
# files.
main() {
	unalias -a # Get rid of whatever distro-specific crud is
		   # invoked before this.
	source_them "" "$to_source"
}

# Do the major changes.
main

# Move out of the multi-distro "home" folder mess.
cd "$h"

# Clean up the environment after the changes.
for clutter in DEBUG msg h custom_sourced to_source source_them main
do
	unset $clutter
done
