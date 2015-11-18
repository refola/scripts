#!/bin/bash
# Cache a single folder, either what's passed as an argument or the
# current working directory.
if [ -n "$1" ]
then
    cd "$1"
    if [ "$?" != "0" ]; then
        echo "Folder doesn't exist. Aborting!"
        exit 1
    fi
else
    echo "No folder passed, so caching \$PWD=$PWD."
fi

echo "Caching folder $PWD."
find . -type f -exec cat {} > /dev/null +
