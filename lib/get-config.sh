#!/bin/bash
## get-config.sh
# Read and output the requested configuration file if found. Otherwise
# copy the default and prompt the user to edit it.

# Sanity check
if ! which cmdir dirname > /dev/null
then
    echo "Could not find all commands.... Exiting."
    exit 1
fi

# This line assumes that this script is in a sibling directory of the
# config directory.
DEFAULTS_PREFIX="$(dirname "$(cmdir "$0")")/config"
# Where the live configs are.
CONFIG_PREFIX="$HOME/.config/refola/scripts"

# Here's how to invoke this script.
USAGE="Usage: $(basename "$0") script_name/config_name [description]

Outputs the contents of the config for script_name/config_name if it
exists. Otherwise copies the default (if found), prints the
description (if given) to stderr, and prompts the user to edit the
config with $EDITOR.

Returns 0 if the config was successfully retrieved and non-zero if
there was an unresolved error.

Config paths are as follows.
Defaults:     $DEFAULTS_PREFIX
Live configs: $CONFIG_PREFIX"

## Usage: get_config_if_exists script/config
# Prints config if it exists, otherwise returns non-zero.
get_config_if_exists() {
    local CFG_PATH="$CONFIG_PREFIX/$1"
    if [ -f "$CFG_PATH" ]
    then
	cat "$CFG_PATH"
	return 0
    else
	return 1
    fi
}

## Usage: copy_default_config script/config
# Copies the default config if it exists, otherwise makes a blank
# config.
copy_default_config() {
    local CFG="$1"
    local FROM="$DEFAULTS_PREFIX/$CFG"
    local TO="$CONFIG_PREFIX/$CFG"
    # Make sure the destination directory exists.
    mkdir -p "$(dirname "$TO")"
    if [ -f "$FROM" ]
    then
	cp "$FROM" "$TO"
    else
	touch "$TO"
    fi
}

## Usage: edit_config_prompt script/config description
# Shows the user the path and description of the given config and asks
# if the user wants to edit it.
## Returns 0 for yes and non-zero for no.
edit_config_prompt() {
    local CFG="$1"
    local CFG_PATH="$CONFIG_PREFIX/$CFG"
    local DESC="$2"
    if [ -n "$DESC" ]
    then
	echo "$CFG: $DESC"
    fi
    echo -e "$CFG has the following configuration:\n\e[1;33m$(cat "$CFG_PATH")\e[0m"
    local ANS
    read -n1 -p "Do you want to edit $CFG: [Yes]/[No] (default: no)? " ANS
    echo
    if [ "$ANS" = y -o "$ANS" = Y ]
    then
	return 0
    else
	return 1
    fi
}

## Usage: edit_config script/config
# Edits the given config with $EDITOR.
edit_config() {
    "$EDITOR" "$CONFIG_PREFIX/$1"
}

## Usage: abort_prompt
# Asks the user if they want to abort.
## Returns 0 for yes and non-zero for no.
abort_prompt() {
    local ANS
    read -n1 -p "Do you want to abort this script and give up [Yes]/[No] (default: yes)? " ANS
    echo
    if [ -z "$ANS" -o "$ANS" = y -o "$ANS" = Y ]
    then
	return 0
    else
	return 1
    fi
}

## Usage: get_config script/config description
# Gets the requested config, copying the default and prompting the
# user for editing as required.
get_config() {
    # WARNING: Everything here except get_config_if_exists must be
    # '>&2'-ified to avoid returning the wrong config.
    local CFG="$1"
    local DESC="$2"
    if ! get_config_if_exists "$CFG"
    then
	copy_default_config "$CFG" >&2
	if edit_config_prompt "$CFG" "$DESC" >&2
	then
	    edit_config "$CFG" >&2
	elif abort_prompt >&2
	then
	    echo -e "\e[01;37mWARNING: \e[00;31m$CFG has not been configured. The script will not run.\e[0m" >&2
	    rm "$CONFIG_PREFIX/$CFG"
	    return 1
	fi
	# By now the config must exist.
	get_config_if_exists "$CFG"
    fi
    return 0
}

## Usage: main
# Gets config iff valid, making sure to output non-config stuff to stderr.
main() {
    if [ -z "$1" ]
    then
	echo "$USAGE" >&2
	exit 1
    else
	get_config "$1" "$2"
	exit $?
    fi
}

main "$@"
