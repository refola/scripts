#!/bin/bash

if [ -z "$1" ]
then
    # This assumes that cmcd is a function that sources this script.
    echo "Usage: cmcd command"
    echo "Changes the working directory to command's location."
else
    # Get command's path, take directory name,
    # and move to there.
    cd "$(dirname "$(cmpath "$1")")"
fi
