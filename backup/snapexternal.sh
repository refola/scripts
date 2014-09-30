#!/bin/bash

# places that the external hard drive might be mounted at
MOUNTS="
/run/media/mark/OT4P
/media/mark/OT4P
/media/OT4P
"

echo "Searching for external hard drive to snapshot...."

for MOUNT in $MOUNTS
do
	if [ -d "$MOUNT" ]
	then
		TO="$MOUNT/snapshots/`date --utc +%F`"
		if [ -d "$TO" ]
		then
			echo "Snapshot $TO already exists. Please wait until tomorrow (UTC) and try again."
			echo "The current time is `date --utc +%F.%H%M:%S` (UTC)."
		else
			FROM="$MOUNT/volume"
			# the btrfs tool already explains what's happening
			#echo "Making snapshot \"$TO\" of external drive volume \"$FROM\"."
			# "-r" for readonly so it can be used for other stuff....
			sudo btrfs subvolume snapshot -r $FROM $TO
			SNAPSHOTTED="true"
		fi
	fi
done

if [ -z "$SNAPSHOTTED" ]
then
	echo "Could not make snapshot."
	if [ -z "$TO" ]
	then
		echo "Could not find drive. Please check your mounts."
	else
		echo "Drive(s) found, but the snapshot already exists."
	fi
else
	echo "Snapshot created."
fi

exit
