#!/bin/bash
## mkcd.sh
# Sourcable script for `mkcd()` function.

# Sourcing changes this to a function context; `local` is correct.
# shellcheck disable=SC2168
local usage="Usage: mkcd possibly-relative/path/to/folder

Makes the given folder if it doesn't already exist and changes the
working directory to it. This is equivalent to calling 'mkdir -p path'
and then 'cd path'."

if [ "$#" != "1" ]; then
    echo "$usage"
else
    mkdir -p "$1"
    # This is sourced and we don't want to exit the interactive session.
    # shellcheck disable=SC2164
    cd "$1"
fi
