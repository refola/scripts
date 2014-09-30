#!/bin/bash
# Home folder backup script, preserving (almost) all important information

# Get script location
DELINKED=`readlink -f "$0"`
HERE="`dirname "$DELINKED"`"
# Set a bunch of variables -- dotted because it doesn't work otherwise
. $HERE/variables.sh

if [ -z "$1" ]
then
	$HERE/usage.sh "`basename $0`" "(almost) all the important stuff in $HOME to ext-formatted \"$AWAY/suffix/$USER/\""
	exit 1
else
	FROM="$HOME/"
	TO="$AWAY/$1/$USER/"
	echo "Syncying $FROM to $TO"
	time rsync $OPTS_MAIN $OPTS_EXT --filter="merge $RULES_LARGE" $FROM $TO
fi

echo -e "\nDone. Please check $RULES_LARGE (shown below) in case something important was excluded.\n"
cat $RULES_LARGE

exit
