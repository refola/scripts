#!/bin/bash
# Home folder small backup script, for backing up to a FAT filesystem

# Get script location
DELINKED=`readlink -f "$0"`
HERE="`dirname "$DELINKED"`"
# Set a bunch of variables -- dotted because it doesn't work otherwise
. $HERE/variables.sh

if [ -z "$1" ]
then
	$HERE/usage.sh "`basename $0`" "a small-but-important part of \"$HOME\" to \"$AWAY/suffix/$USER/\""
	exit 1
else
	FROM="$HOME/"
	TO="$AWAY/$1/$USER/"
	echo "Syncying $FROM to $TO"
	time rsync $OPTS_MAIN $OPTS_FAT --filter="merge $RULES_SMALL" $FROM $TO
fi

echo -e "\nDone. Please check the rules file \"$RULES_SMALL\" (shown below) in case something important was excluded.\n"

cat $RULES_SMALL

exit
