#!/bin/bash
# Phone backup script, preserving (almost) all important information.

# Get script location.
DELINKED=`readlink -f "$0"`
HERE="`dirname "$DELINKED"`"
# Set a bunch of variables -- dotted because it doesn't work otherwise
. $HERE/variables.sh

TO="$HOME/phone/backup/"

if [ -z "$1" ]
then
	$HERE/usage.sh "`basename $0`" "your phone from \"$AWAY/suffix/\" to \"$TO\"."
	exit 1
else
	FROM="$AWAY/$1/"
	echo "Syncying $FROM to $TO"
	time rsync $OPTS_MAIN --filter="merge $RULES_PHONE" $FROM $TO
fi

echo -e "\nDone. Please check the rules file \"$RULES_PHONE\" (shown below) in case something important was excluded.\n"

cat $RULES_PHONE

exit
