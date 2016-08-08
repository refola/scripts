#!/bin/bash
## ecat.sh
# Echo the name of and "cat" each passed file.

if [ -z "$1" ]; then
    echo "Usage: ecat filename [...]"
    echo "This echoes the name of each file and then cats it."
    exit 1
fi

while [ -n "$1" ]; do
    echo -e "\e[0;1m$1\e[0m"
    cat "$1"
    shift
done
