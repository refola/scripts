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

usage="Usage: $(basename "$0") script_name/config_name [options]

Outputs the contents of the config for script_name/config_name if it
exists. Otherwise copies the default (if found) and prompts the user
to edit the config with \$EDITOR.

Options are as follows:
    -what-do  The next parameter is used to tell the user what the
              config does.
    -var-rep  Enable replacement of variable expressions like
              \$foo and \${foo:-bar} with the corresponding value.
    -path     Output the path to the config instead of its contents.
              This option overrides normal make-sure-the-config-exists
              functionality.

This script returns 0 if the config was successfully retrieved and
non-zero if there was an unresolved error.

Config paths are as follows.
Defaults:     $defaults_prefix
Live configs: $config_prefix"

# Global variables: Set by main, but defined here for clarity.
config_name=""           # The full config name, including the script,
                         # e.g., "script_name/config_name".
config_path=""           # The full path to the config file.
default_config_path=""   # The full path to the default config file.
path_only=""             # Whether or not the config's path should be
                         # outputted instead of getting the contents.
var_rep=""               # Whether or not variables in the config
                         # should be replaced before outputting the
                         # config.
what_do=""               # A description of what the config does.

# Outputs error message to stderr, prefixed with "Error: " in red.
error() {
    echo -e "$(red "Error:") $*" >&2
}

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

## Usage: color code text
# Adds code to make text color.
color() { echo -n "\e[${1}m${*:2}\e[0m"; } # "{*:2}" to output 1 string.
# Shortcut functions to change text color.
red() { color '0;31' "$@"; }
yellow() { color '1;33' "$@"; }

# Explains to the user everything we know about the config.
explain_config() {
    if [ -n "$what_do" ]; then
	echo -e "$config_name: $(yellow "$what_do")"
    fi
    if [ -f "$default_config_path" ]; then
	echo "Here's the default configuration for $config_name."
	echo -e "$(yellow "$(cat "$default_config_path")")"
    else
	echo "No default configuration found for $config_name. Using blank config."
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
	    *    ) echo -e "$(red "$config_name has not been configured. The script will not run.")"
		   return 1
		   ;;
	esac
	return 0
    fi
}

# Outputs the configuration, converting variable expressions if
# $var_rep is set.
output-config() {
    local cfg
    if ! cfg="$(cat "$config_path")"; then
        error "Could not read config at '$config_path'."
        return 1
    elif [ -n "$var_rep" ]; then
        if ! cfg="$(eval "echo \"$cfg\"")"; then
            error "Could not do variable replacements in config:\n$(yellow "$cfg")"
            return 1
        fi
    fi
    echo "$cfg"
}

## Usage: parse-args "$@"
# Sets global variables based on args.
parse-args() {
    config_name="$1"
    shift
    while [ "$#" != "0" ]; do
        case "$1" in
            -what-do)
                what_do="$2"
                shift 2
                ;;
            -var-rep)
                var_rep="true"
                shift
                ;;
            -path)
                path_only="true"
                shift
                ;;
            *)
                error "Skipping unknown argument '$1'."
                return 1
                ;;
        esac
    done
    config_path="$config_prefix/$config_name"
    default_config_path="$defaults_prefix/$config_name"
}

## Usage: main "$@"
# Gets config iff valid, outputting non-config stuff to stderr.
main() {
    if ! parse-args "$@"; then
        # Figure out what's requested, otherwise fail.
        error "Could not parse all arguments."
        exit 1
    elif [ -z "$config_name" ]; then
        # If no config name is passed, then this cannot run.
        error "Missing mandatory argument: configuration name."
        echo "$usage" >&2
	exit 1
    elif [ -n "$path_only" ]; then
        # Just echo the path and exit.
        echo "$config_path"
        exit 0
    else
        # Do the normal config-getting stuff.
	if ! can_read_config >&2
	then
            error "Could not get config."
	    exit 1
	else
	    output-config
	    exit $?
	fi
    fi
}

main "$@"
