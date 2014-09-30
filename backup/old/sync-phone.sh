#!/bin/bash

# Get script location.
DELINKED=`readlink -f "$0"`
HERE="`dirname "$DELINKED"`"
# Set a bunch of variables -- dotted because it doesn't work otherwise
. $HERE/variables.sh

TO_PHONE="$HERE/home-medium-to-phone-fat.sh"
FROM_PHONE="$HERE/phone-to-home.sh"

if [ -z "$1" ]
then
	echo "Usage: `basename $0` suffix"
	echo "This calls the \"$TO_PHONE\" and \"$FROM_PHONE\" scripts for the given location, then backs up the sound stuff to a separate place to make things work with Apollo on the phone."
	echo "A list of locations in \"$AWAY\" follows."
	ls -A $AWAY
	exit 1
else
	echo "Running \"$TO_PHONE $1\" to backup to the phone."
	$TO_PHONE $1
	echo -e "\n\nRunning \"$FROM_PHONE $1\" to backup the phone."
	$FROM_PHONE $1

	SOUND_FROM="/home/$USER/audio/"
	SOUND_TO="$AWAY/$1/Sound/"
	CMD="rsync $OPTS_MAIN $OPTS_FAT $SOUND_FROM $SOUND_TO"
	echo -e "\n\nRunning \"$CMD\" to sync sound to phone."
	$CMD
fi

exit
