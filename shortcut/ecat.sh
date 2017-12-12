#!/bin/bash
## ecat.sh
# Echo the name of and "cat" each passed file.

if [ -z "$1" ]; then
    echo "Usage: ecat filename [...]"
    echo "This echoes the name of each file and then cats it."
    exit 1
fi

for x in "$@"; do
    echo -e "\e[0;1m$x\e[0m"
    cat "$x"
    echo # This is in case the previous file doesn't end with a newline.
done
