#!/bin/bash

# Custom .bashrc that just sources other files.

# "true" or not "true": Should debugging messages be printed?  "true"
# is useful for figuring out which sourced thing is causing errors,
# while not "true" is good for general use when things are working.
DEBUG="false" # not "true"
#DEBUG="true"

# Usage: msg message
# Prints message iff DEBUG is true.
msg(){
    if [ "$DEBUG" = "true" ]; then
        echo "$@"
    fi
}
msg "DEBUG=$DEBUG"

# These variables are required for bootstrapping Bash customizations.
h="/home/$USER" # local version of $H
custom_sourced="$h/sampla/samselpla/scripts/sourced" # TODO: fix hard-coding

# Custom behaviour locations.
# Note: Do not include /etc/bash_completion.d. It's already dealt with
# by /etc/bash_completion, which has a bunch of custom functions that
# /etc/bash_completion.d needs.
to_source=(
    /etc/bash_completion
    "$HOME/.profile"
    "$custom_sourced"
)

# Usage: source_them thing1 [thing2 [...]]
# Source everything given, maximally recursively.
source_them() {
    local x
    for x in "$@"; do
        if [ -d "$x" ]; then
            msg "Getting contents of $x to source"
            source_them "$x"/*
        elif [ -f "$x" ]; then
            msg "Sourcing $x"
            . "$x"
        else
            msg "Cannot source $x"
        fi
    done
}

source_them "${to_source[@]}" # Source everything.
cd "$h" # Move out of the multi-distro "home" folder mess.

# Clean up the environment after the changes.
for clutter in DEBUG msg h custom_sourced to_source source_them
do
    unset $clutter
done
unset clutter # Because keeping track of the clutter generates more clutter.
