#!/bin/bash
# Gaming home backup script

# Get script location
DELINKED=`readlink -f "$0"`
HERE="`dirname "$DELINKED"`"
# Set a bunch of variables -- dotted because it doesn't work otherwise
. $HERE/variables.sh

FROM="/home/gaming/"
if [ -z "$1" ]
then
	$HERE/usage.sh "`basename $0`" "$FROM to ext-formatted \"$AWAY/suffix/gaming/\""
	exit 1
else
	TO="$AWAY/$1/gaming/"
	echo "Syncying $FROM to $TO"
	time rsync $OPTS_MAIN $OPTS_EXT $FROM $TO
fi

echo -e "\nDone."

exit
