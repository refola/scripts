#!/bin/bash
# Home folder medium backup script, for backing up to a phone's FAT-formatted SD card

# Get script location
DELINKED=`readlink -f "$0"`
HERE="`dirname "$DELINKED"`"
# Set a bunch of variables -- dotted because it doesn't work otherwise
. $HERE/variables.sh

if [ -z "$1" ]
then
	$HERE/usage.sh "`basename $0`" "all of $HOME that can reasonably be used on a phone to \"$AWAY/suffix/$USER/\""
	exit 1
else
	FROM="$HOME/"
	TO="$AWAY/$1/$USER/"
	echo "Syncying $FROM to $TO"
	time rsync $OPTS_MAIN $OPTS_FAT --filter="merge $RULES_MEDIUM" $FROM $TO
fi

echo -e "\nDone. Please check the rules file \"$RULES_MEDIUM\" (shown below) in case something important was excluded.\n"

cat $RULES_MEDIUM

exit
