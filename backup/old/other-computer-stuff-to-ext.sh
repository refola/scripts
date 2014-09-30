#!/bin/bash

# Get script location.
DELINKED=`readlink -f "$0"`
HERE="`dirname "$DELINKED"`"
# Set a bunch of variables -- dotted because it doesn't work otherwise
. $HERE/variables.sh

TO_PHONE="$HERE/home-medium-to-phone-fat.sh"
FROM_PHONE="$HERE/phone-to-home.sh"

PLACES="
gaming
minecraft
"

if [ -z "$1" ]
then
	$HERE/usage.sh "`basename $0`" "each /home/place/ to ext-formatted \"$AWAY/suffix/place/\", with places being: $PLACES"
	exit 1
else
	for PLACE in $PLACES
	do
		FROM="/home/$PLACE/"
		TO="$AWAY/$1/$PLACE/"
		RULES="$HERE/rules-$PLACE"
		echo "Syncing $FROM to $TO"
		time rsync $OPTS_MAIN $OPTS_EXT --filter="merge $RULES" $FROM $TO
	done
fi

exit
