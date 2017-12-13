#!/bin/bash
## cdh.sh
# Sourcable script for `cdh()` function.

# Sourcing changes this to a function context; `local` is correct.
# shellcheck disable=SC2168
local usage="Usage: cdh [path]

If path is given, then change the working directory to the given path
and sets \$H to the path.

Otherwise, changes the working directory to \$H if it isn't already,
and display this usage message if it is."

if [ -z "$1" ]; then
    if [ "$PWD" = "$H" ]; then
        echo "$usage" >&2
        # Sourcing changes this to a function context; `return` is correct.
        # shellcheck disable=SC2168
        return 1
    else
        pcd "$H"
    fi
else # Change to the given path and set `$H` to the path.
    pcd "$1"
    export H="$PWD" # `$PWD` gets rid of relative paths.
fi
