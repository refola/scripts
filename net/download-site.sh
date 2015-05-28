#!/bin/bash
DEST="/home/mark/doc/sites"
if [ -z "$1" ]; then
    echo "Usage: $(basename "$0") domain.tld"
    echo "This downloads the site at domain.tld and puts it in $DEST."
else
    cd $DEST
    wget -c --mirror --wait=0.2 "$1"
fi
exit
