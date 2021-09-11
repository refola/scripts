#!/usr/bin/env sh
## cdl.sh
# Sourcable script for `cdl()` function.

# SC3043: I'm using a "POSIX" shebang so ShellCheck can help me avoid
# Bash-isms so this works in Zsh, which does indeed support "local".
##
# shellcheck disable=SC3043
local force vars_path h pwd

if [ "$1" = "-f" ]; then
    force=true
    shift
fi

# Get place to load variables from.
vars_path="$(get-config "var-save/$*" -path)"

if [ -z "$1" ] || [ ! -e "$vars_path" ]; then
    echo "Usage: cdl [-f] name"
    echo "Restores \$PWD and \$H with given name, as saved by 'cds'."
    echo "With '-f' also makes referenced paths exist before cd'ing."
    # Show list of saved variable sets
    vars_path="$(get-config "var-save" -path)"
    echo "List of saved path names:"
    ls -m "$vars_path"
else
    # Set paths.
    h="$(cat "$vars_path/H")"
    pwd="$(cat "$vars_path/PWD")"
    # Force existence if applicable
    [ -n "$force" ] && mkdir -p "$pwd" "$h"
    # Load paths indirectly via appropriate commands.
    cdh "$h"
    pcd "$pwd"
fi
