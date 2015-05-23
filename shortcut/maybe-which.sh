#!/bin/bash

if [ -z "$1" ]
then
    echo "Usage: $(cmpath "$0") command"
    echo "Outputs the result of 'which command' if it works."
    echo "Otherwise, outputs the original input."
else
    # See if the argument is found in $PATH and transform accordingly.
    CMD_PATH="$(which "$1" 2> /dev/null)"
    if [ $? = "1" ]
    then
	CMD_PATH="$1"
    fi
    echo -n "$CMD_PATH"
fi
