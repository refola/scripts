#!/bin/bash
# Restore file/folder from a btrfs snapshot.

# TODO: This should be able to handle everything from assuming the
# "backup-btrfs" script has been used for snapshots and auto-inferring
# all the snapshot stuff from a full destination path. For now it just
# defaults to my main personal usecase and takes extra parameters for
# other snapshot and destination directories.

snapdir="/mnt/@snapshots/@home-mark"
cd $snapdir # because ls'ing "$snapdir/*/" doesn't work the same
# get last folder in snapshot directory
lastsnap="$(ls -d */ | tail -n 1 | rev | cut -c2- | rev)"
snapshot="$snapdir/$lastsnap"

destination="/mnt/@home/mark"

if [ -z "$1" ]
then
    echo "Usage: $(basename "$0") path [snapshot destination]"
    echo "Restores contents of path from snapshot to destination."
    echo
    echo "Defaults:"
    echo "  snapshot:     $snapshot"
    echo "  destination:  $destination"
    echo
    echo "Note: snapshot and destination must be on subvolumes"
    echo "in the same btrfs mount point. Otherwise it will duplicate"
    echo "all the data, ignoring btrfs's copy-on-write features."
    exit 1
fi
path="$1"

if [ ! -z "$3" ]
then
    snapshot="$2"
    destination="$3"
fi

cp --recursive --reflink --preserve=all "$snapshot/$path" "$destination/$path"
