#!/bin/bash

# subvolumes to snapshot
# see output of "sudo btrfs subvolume list $BASE | grep -v snapshot | cut -c 34-" for ideas
VOLS="
@fedora
@kubuntu
@kylin
@suse
@home
@home/gaming
@home/guest
@home/mark
@home/minecraft
@home/shared
@home/shared/media
"
# @oldhomes

# place that contains the btrfs partition directly, not just a particular subvolume
BASE="/mnt"
TIME="`date --utc +%F`"
if [ "$1" == "--now" ]
then
	TIME="`date --utc +%F_%H-%M-%S`"
fi

# where to make the snapshots
SNAPDIR="$BASE/@snapshots/$TIME"
if [ "$1" == "--custom" ]
then
	SNAPDIR="$2"
fi

# ensure $SNAPDIR exists
if [ -e "$SNAPDIR" ]
then
	echo "Using existing snapshot directory $SNAPDIR. Snapshots might already exist."
else
	echo "Creating snapshot directory $SNAPDIR."
	sudo mkdir $SNAPDIR
fi

echo "Searching for internal hard drive subvolumes to snapshot...."

for VOL in $VOLS
do
	# the tr bit converts slashes to dashes so it's a valid folder name
	TO="$SNAPDIR/`echo $VOL | tr / -`"
	FROM="$BASE/$VOL"
	if [ -d "$TO" ]
	then
		echo "Snapshot $TO already exists."
		ALREADYEXISTS="true"
	else
		# the btrfs tool already explains what's happening
		#echo "Making snapshot \"$TO\" of volume \"$FROM\"."
		# "-r" for readonly so it can be used for other stuff....
		sudo btrfs subvolume snapshot -r $FROM $TO
	fi
done

if [ -z "$ALREADYEXISTS" ]
then
	echo "Snapshots created."
else
	echo "At least one snapshot already existed. Please wait until tomorrow (UTC) and try again."
	echo "Otherwise you can pass the \"--now\" option or pass \"--custom [PATH]\" to make snapshots in PATH."
	echo "The current time is `date --utc +%F.%H%M:%S` (UTC)."
fi

exit
