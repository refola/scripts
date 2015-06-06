#!/bin/bash
## get-config.sh
# Read and output the requested configuration file if found. Otherwise
# copy the default and prompt the user to edit it.

# Sanity check
if ! which cmdir dirname > /dev/null
then
    echo "Could not find all required commands.... Exiting." >&2
    exit 1
fi

# This line assumes that this script is in a sibling directory of the
# config directory.
defaults_prefix="$(dirname "$(cmdir "$0")")/config"
# Where the live configs are.
config_prefix="$HOME/.config/refola/scripts"

# Here's how to invoke this script.
usage="Usage: $(basename "$0") script_name/config_name [description]

Outputs the contents of the config for script_name/config_name if it
exists. Otherwise copies the default (if found), shows the description
(if given) to the user, and prompts the user to edit the config with
\$EDITOR.

Returns 0 if the config was successfully retrieved and non-zero if
there was an unresolved error.

Config paths are as follows.
Defaults:     $defaults_prefix
Live configs: $config_prefix"

# These variables are set by main, but defined here for clarity.
config_name=""
config_description=""
config_path=""
default_config_path=""


# Copies the default config if it exists, otherwise makes a blank
# config.
copy_default_config() {
    # Make sure the destination directory exists.
    mkdir -p "$(dirname "$config_path")"
    if [ -f "$default_config_path" ]
    then
	cp "$default_config_path" "$config_path"
    else
	touch "$config_path"
    fi
}

# Usage: color code text
# Adds code to make text color.
color() { echo -n "\e[${1}m${2}\e[0m"; }
# Usage: yellow text
# Adds code to makes text yellow.
yellow() { color '1;33' "$1"; }

# Explains to the user everything we know about the config.
explain_config() {
    if [ -n "$config_description" ]; then
	echo -e "$config_name: $(yellow "$config_description")"
    fi
    if [ -f "$default_config_path" ]; then
	echo "Here's the default configuration for $config_name."
	echo -e "$(yellow "$(cat "$default_config_path")")"
    else
	echo "No default configuration found for $config_name. Going with blank config."
    fi
}

# Checks if the configuration can be retrieved, interactively loading
# defaults and prompting the user to edit the config as
# appropriate. Returns 0 if the configuration appears to be
# retrievable and non-zero if the script should be aborted.
can_read_config() {
    if [ -f "$config_path" ]; then
	return 0
    else
        explain_config
	# Echo question separately because 'read' does not support color codes.
	echo -e -n "[$(yellow A)]bort (default) / use [$(yellow D)]efault config / [$(yellow E)]dit config? "
	local ans; read -n1 ans
	echo # because 'read' doesn't
	case "$ans" in
	    [dD] ) copy_default_config
		   ;;
	    [eE] ) copy_default_config
		   "$EDITOR" "$config_path"
		   ;;
	    *    ) echo -e "$(color '0;31' "$config_name has not been configured. The script will not run.")"
		   return 1
		   ;;
	esac
	return 0
    fi
}

## Usage: main "$@"
# Gets config iff valid, making sure to output non-config stuff to stderr.
main() {
    if [ -z "$1" ]
    then
	echo "$usage" >&2
	exit 1
    else
	config_name="$1"
	config_description="$2"
	config_path="$config_prefix/$config_name"
	default_config_path="$defaults_prefix/$config_name"
	if ! can_read_config >&2
	then
	    exit 1
	else
	    cat "$config_path"
	    exit $?
	fi
    fi
}

main "$@"
