#!/bin/bash
DEST="/home/mark/doc/sites"
if [ -z "$1" ]; then
	echo "Usage: downloadsite.sh domain.tld"
	echo "This downloads the site at domain.tld and puts it in $DEST."
else
	cd $DEST
	wget -c --mirror --wait=1 $1
fi
exit
