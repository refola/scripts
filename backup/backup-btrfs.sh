#!/bin/bash
##
# btrfsbackup.sh
##
# Uncopyright 2014-2015 Mark Haferkamp. This code is dedicated to the
# public domain. Use it as you will.
##
# Makes sure internal btrfs snapshots are up-to-date for today. Then,
# if the external drive is connected, makes sure that external backups
# match the latest internal backups, bootstrapping new snapshot clones
# if required. See <1> for reference.
##
# 1: https://btrfs.wiki.kernel.org/index.php/Incremental_Backup


### limitations ###

# This only works with a single "internal" btrfs "drive" (may be
# multiple disks with btrfs RAID or whatever) to make and clone
# snapshots from.

# For each subvolume to backup, the external drive's latest snapshot
# must have a matching snapshot in the internal drive (which acts as
# the parent for btrfs updates).

# This only syncs the latest internal snapshots to the external drive.

# This only handles one external drive attached at a time.

# This assumes that you only want one snapshot per UTC day, though
# this can be overridden by passing "--now" to this script to change
# backup granularity to per-second.

# This does not delete old snapshots as drive space fills up. You must
# do this manually since btrfs breaks when the drive's full.


### pre-run sanity check ###
if ! which btrfs get-config > /dev/null
then
    echo "Error: Could not find all necessary commands."
    exit 1
fi


### get configuration, exiting on error ###

# Shortcut variable for use with get-config.
THIS="backup-btrfs"
# where internal drive's btrfs partition root is mounted
INTROOT="$(get-config "$THIS/internal-root")" || exit 1
# where to make the internal drive's snapshots
INTSNAPDIR="$INTROOT/$(get-config "$THIS/internal-snapshot-directory")" || exit 1
# places that the external hard drive might be mounted at
EXTERNS="$(get-config "$THIS/external-roots")" || exit 1
# subvolumes to snapshot (see "btrfs subvolume list $INTROOT")
VOLS="$(get-config "$THIS/subvolumes")" || exit 1


### derived global variables ###

# where to make/find/update external snapshot clones
for EXTROOT in $EXTERNS
do
    if [ -d "$EXTROOT" ]
    then
	# backup to the root of the external drive.
	EXTSNAPDIR="$EXTROOT"
    fi
done
if [ -z "$EXTSNAPDIR" ]
then
    echo "External drive not found. Only doing internal snapshotting."
fi

# time to use in naming snapshot directories
TIME="$(date --utc +%F)"
if [ "$1" == "--now" ]
then
    TIME="$(date --utc +%F_%H-%M-%S)"
fi


### btrfs functions ###

# Usage: clonesub fromsnap todir
# Clone subvolume at fromsnap to same-named snapshot in todir. Useful
# for copying between disks.
# Result: todir/part_of_fromsnap_after_slash is now a clone of fromsnap
clonesub() {
    local FROM=$1
    local TODIR=$2
    sudo btrfs send "$FROM" | sudo btrfs receive "$TODIR"
}

# Usage: cloneup fromparent fromnew todir
# Update existing btrfs clone from newer snapshot version.
# Assumption: todir/part_of_fromparent_after_slash is already a clone
# of fromparent
# Result: todir/part_of_fromnew_after_slash is a clone of fromnew
cloneup() {
    local FROMPARENT=$1
    local FROMNEW=$2
    local TODIR=$3
    sudo btrfs send -p "$FROMPARENT" "$FROMNEW" | sudo btrfs receive "$TODIR"
}

# Usage: syncem
# Sync, then do "btrfs filesystem sync" for both INTSNAPDIR and
# EXTSNAPDIR.  It's called "syncem" as a contraction of "sync them",
# since it syncs more than one thing, i.e., "them".  This is important
# after doing at least some btrfs snapshot operations.
syncem() {
    # the wiki lists sync as part of its snapshot cloning steps,
    # but i think "btrfs filesystem sync" might also be in order
    sync
    btrfs filesystem sync "$INTROOT" > /dev/null
    if [ -n "$EXTSNAPDIR" ]
    then
	btrfs filesystem sync "$EXTSNAPDIR" > /dev/null
    fi
}


### snapshotting functions ###

# Usage: bootstrap volume
# Bootstrap initial external snapshot clone of volume.
bootstrap() {
    local VOL=$1
    
    # The tr bit converts slashes to dashes so it's a valid folder name.
    local FROM="$INTSNAPDIR/$(timedvol "$VOL")"
    local TO="$EXTSNAPDIR/$(san "$VOL")"
    clonesub "$FROM" "$TO"
}

# Usage: incremental volume oldtime
# Incrementally update external snapshot of volume.
incremental() {
    local VOL=$1
    local OLDTIME=$2
    # no NEWTIME, since that's gotten via timedvol()
    
    # The tr bit converts slashes to dashes so it's a valid folder name.
    local OLD="$INTSNAPDIR/$(san "$VOL")/$OLDTIME"
    local FROM="$INTSNAPDIR/$(timedvol "$VOL")"
    local TO="$EXTSNAPDIR/$(san "$VOL")"
    sudo btrfs send -p "$OLD" "$FROM" | sudo btrfs receive "$TO"
}

# Usage: internal volume
# Make an internal snapshot of volume.
internal() {
    local VOL=$1
    
    # The tr bit converts slashes to dashes so it's a valid folder name.
    local FROM="$INTROOT/$VOL"
    local TO="$INTSNAPDIR/$(timedvol "$VOL")"
    # The btrfs tool already explains what's happening.
    # "-r" is for readonly so it can be used for cloning.
    sudo btrfs subvolume snapshot -r "$FROM" "$TO"
    
    # Make sure snapshot creation is fully propagated.
    syncem
}


### utility functions ###

# Usage: LAST_BACKUP="$(lastbak volume snapdir)"
# Get name of last backup for volume in snapdir, or empty string if
# there is no backup.
lastbak() {
    local VOL=$(san "$1")
    local SNAPDIR=$2
    local DIR="$SNAPDIR/$VOL"
    # NOTE: This assumes that the snapshot directory is empty iff
    # backups have been made with this script before.
    if [ -n "$(ls "$DIR")" ]
    then
	# get list of existing snapshots, get last one, and remove leading './'
	cd "$DIR" # make the leading part of find's results a deterministic "./"
	find . -maxdepth 1 -mindepth 1 | sort | tail -n 1 | cut -c3-
    fi
}

# Usage: SANITIZED="$(san volume)"
# Sanitize volume's name to be a suitable snapshot folder name.
san() {
    echo -n "$1" | tr / -
}

# Usage: startsudo; stuff; stopsudo
# Activates sudo mode, starts a sudo-refreshing loop, saves the loop's
# process number to $SUDO_PID, and sets a C-c trap to stop the loop on
# abrupt exit.
# Note: Failure to run stopsudo after running this will leave a stray
# sudo-refreshing process running.
startsudo() {
    sudo -v
    ( while true; do sudo -v; sleep 50; done; ) &
    SUDO_PID="$!"
    trap stopsudo SIGINT SIGTERM
}

# Usage: stopsudo
# Kills the sudonotimeout loop and cancels the C-c trap.
stopsudo() {
    kill "$SUDO_PID"
    trap - SIGINT SIGTERM
}

# Usage: TIME_INCLUDING_VOLUME_PATH="$(timedvol volume)"
# Get time-including name for volume's latest snapshot, complete with
# sanitized volume name.
# Note: This uses the global TIME var so the caller doesn't have to.
timedvol() {
    local VOL=$(san "$1")
    echo -n "$VOL/$TIME"
}

# Usage: voldir volume
# Ensure that the directory for volume exists in $INTSNAPDIR, and also
# for $EXTSNAPDIR if the external drive is available.
voldir() {
    local VOL=$(san "$1")
    if [ ! -e "$INTSNAPDIR/$VOL" ]
    then
	sudo mkdir "$INTSNAPDIR/$VOL"
    fi
    if [ -n "$EXTSNAPDIR" ]
    then
	if [ ! -e "$EXTSNAPDIR/$VOL" ]
	then
	    mkdir "$EXTSNAPDIR/$VOL"
	fi
    fi
}


### main stuff ###

# Make sure sudo doesn't time out.
echo "Obtaining sudo privilege"
startsudo # Note: Make sure to run stopsudo later to kill the loop.

for VOL in $VOLS
do
    # Set up directories for the next stuff.
    voldir "$VOL"

    # Set up internal snapshot, ensuring that it's from today.
    INTLASTBAK="$(lastbak "$VOL" "$INTSNAPDIR")"
    if [ "$INTLASTBAK" != "$TIME" ]
    then
	internal "$VOL"
    else
	echo "There's already a snapshot from $TIME for $VOL"
    fi

    # Check if we should do this next part.
    if [ -z "$EXTSNAPDIR" ]
    then
	continue
    fi

    # Set up external snapshot.
    EXTLASTBAK="$(lastbak "$VOL" "$EXTSNAPDIR")"
    if [ -z "$EXTLASTBAK" ]
    then
	bootstrap "$VOL"
    else
	if [ "$EXTLASTBAK" != "$TIME" ]
	then
	    incremental "$VOL" "$EXTLASTBAK"
	else
	    echo "There's already a backup from $TIME for $VOL."
	fi
    fi
done

# Cleanup forked subshell and exit.
echo "Killing sudo refresher before exiting."
stopsudo
exit
