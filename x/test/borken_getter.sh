#!/usr/bin/env bash

# Shortcut function to get a config with description, exiting on fail.
_script_name="foo"
get() {
    local var_name="$1"
    local cfg_name="$2"
    local cfg_desc="$3"
    echo "var_name=$var_name"
    echo "cfg_name=$cfg_name"
    echo "cfg_desc=$cfg_desc"
    local result
    result="$(get-config "$_script_name/$cfg_name" -what-do "$cfg_desc")"
    if [ $? != "0" ]; then
        echo "Error getting config $cfg_name. Exiting." >&2
        exit 1
    else
        # Save config to variable.
        echo "evaling \"$var_name='$result'\"."
        eval "$var_name='$result'"
    fi
}
# Get the config.
get var_name config_name "config description"

echo "vn=$var_name"
