#!/usr/bin/env bash

# Shortcut function to get a config with description, exiting on fail.
_script_name="foo"
get() {
    local result
    result="$(get-config "$_script_name/$2" -what-do "$3")"
    if [ $? != "0" ]; then
        echo "Error getting config $1. Exiting." >&2
        exit 1
    else
        echo "Got config $1. Saving to variable \$$1." >&2
        eval "$1='$result'"
    fi
}
# Get the config.
get var_name config_name "config description"

echo "vn=$var_name"
