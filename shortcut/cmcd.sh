#!/bin/bash
## cmcd.sh
# Sourcable script for `cmcd()` function.

if [ -z "$1" ]; then
    echo "Usage: cmcd command"
    echo "Changes the working directory to command's location."
else # Get command's path, take directory name, and move to there.
    # This is sourced and we don't want to exit the interactive session.
    # shellcheck disable=SC2164
    cd "$(dirname "$(cmpath "$1")")"
fi
