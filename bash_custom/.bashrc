#!/usr/bin/env bash

# Custom .bashrc that just sources other files.

# "true" or not "true": Should debugging messages be printed?  "true"
# is useful for figuring out which sourced thing is causing errors,
# while not "true" is good for general use when things are working.
DEBUG="false" # not "true"
#DEBUG="true"

# Usage: __msg message
# Prints message iff DEBUG is true.
__msg(){
    if [ "$DEBUG" = "true" ]; then
        echo "$@"
    fi
}
__msg "DEBUG=$DEBUG"

# These variables are required for bootstrapping Bash customizations.
__h="/home/$USER" # local version of $H
__custom_sourced="$__h/sampla/samselpla/scripts/sourced" # TODO: fix hard-coding

# Custom behaviour locations.
# Note: Do not include /etc/bash_completion.d. It's already dealt with
# by /etc/bash_completion, which has a bunch of custom functions that
# /etc/bash_completion.d needs.
__to_source=(
    /etc/bash_completion
    "$HOME/.profile"
    "$__custom_sourced"
)

# Usage: __source_thing thing [...]
# Source every thing given, maximally recursively.
__source_thing() {
    local x
    for x in "$@"; do
        if [ -d "$x" ]; then
            __msg "Getting contents of $x to source"
            __source_thing "$x"/*
        elif [ -f "$x" ]; then
            __msg "Sourcing $x"
            . "$x"
        else
            __msg "Cannot source $x"
        fi
    done
}

__source_thing "${__to_source[@]}" # Source everything.

# We don't want to exit the interactive shell, even if `cd` fails.
# shellcheck disable=SC2164
cd "$__h" # Move out of the multi-distro "home" folder mess.

# Clean up the environment after the changes.
for __cleanup_variable in DEBUG __msg __h __custom_sourced __to_source __source_thing; do
    unset "$__cleanup_variable"
done
unset __cleanup_variable
