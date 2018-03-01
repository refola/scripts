#!/bin/bash
# Restore file/folder from a btrfs snapshot.

# TODO: Automagically retrieve config from `backup-btrfs` script
# config and `/etc/fstab`, and then make autocomplete.

## Usage: get config-name config-description
# Echoes the requested config back to the script, possibly interacting
# with the user to get initial config if it doesn't exist yet.
get() { get-config "restore-from-btrfs-snapshot/$1" -what-do "$2" || exit 1; }

# Get configurations.
snapdir="$(get "snapdir"
               "directory where your home directory's snapshots are located")"
destination="$(get "destination"
                   "directory under the same mount point as 'snapdir' where your
home directory is located (_not_ under '/home'!)")"


# get last folder in snapshot directory
snapshot="$(find "$snapdir" -mindepth 1 -maxdepth 1 | tail -n 1)"

usage="Usage: $(basename "$0") path [snapshot destination]
Restores contents of 'path' from 'snapshot' to 'destination'.

Defaults:
  snapshot:     $snapshot
  destination:  $destination

Note: snapshot and destination must be on subvolumes in the same btrfs
mount point. Otherwise it will duplicate all the data, ignoring
btrfs's copy-on-write features, and wasting that much space."

if [ -z "$1" ]; then
    echo "$usage"
    exit 1
fi
path="$1"

if [ ! -z "$3" ]; then
    snapshot="$2"
    destination="$3"
fi

cp --recursive --reflink --preserve=all "$snapshot/$path" "$destination/$path"
