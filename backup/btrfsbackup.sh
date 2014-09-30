#!/bin/bash
# btrfsbackup.sh
# 
# Uncopyright 2014 Mark Haferkamp. This code is dedicated to the public domain. Use it as you will.
# 
# Makes sure internal btrfs snapshots are up-to-date for today. Then, if the
# external drive is connected, makes sure that external backups match the latest
# internal backups, bootstrapping new snapshot clones if required.
# See https://btrfs.wiki.kernel.org/index.php/Incremental_Backup for reference.

# NOTE: You'll almost certainly have to change the variables to match your own setup. Also, this script makes the following assumptions:
# * You have only one "internal" btrfs "drive" (may be multiple disks with btrfs RAID or whatever) to make and clone snapshots from.
# * The internal and external drives' snapshot directory structure is snapshotdir/vol/date.
# * For each subvolume to backup, the internal drive's snapshot matching the latest external drive's snapshot is still saved in the internal drive.
# * You don't care about syncing every internal snapshot to the external drive, but rather only the latest.
# * You only have one external drive attached at a time.
# * By default you only want one snapshot per day. This can be overridden by passing "--now" to this script to change backup granularity to per-second.
# * You have your own system for dealing with old snapshots on each drive before it runs short on space and breaks btrfs.

### HOW BTRFS CLONES SUBVOLUMES ###

# clone /src/a/foo to /dest:
# 	foo's clone is named /dest/foo
# clone /src/b/bar to /dest with parent /src/a/foo to /dest:
# 	bar's clone is named /dest/bar
# 	only works if /dest/foo is already a clone of /src/a/foo
# 	requires foo and bar to have different names

# The key point is that we must specify /dest as the location, not name, of a
# btrfs subvolume/snapshot clone.


### GLOBAL VARS ###

# where internal drive's btrfs partition root (not just a subvolume) is mounted
INTROOT="/mnt"

# where to make the internal drive's snapshots
INTSNAPDIR="$INTROOT/@snapshots"

# places that the external hard drive might be mounted at
EXTERNS="
/run/media/mark/OT4P
/media/mark/OT4P
/media/OT4P
"

# where to make/find/update external snapshot clones
for EXTROOT in $EXTERNS
do
	if [ -d "$EXTROOT" ]
	then
		EXTSNAPDIR="$EXTROOT" # I backup to the root of the external drive.
	fi
done
if [ -z "$EXTSNAPDIR" ]
then
	echo "External drive not found. Only doing internal snapshotting."
fi

# subvolumes to snapshot
# See output of "sudo btrfs subvolume list $INTROOT | grep -v SNAPSHOTDIRECTORY" for ideas.
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

# time to use in naming snapshot directories
TIME="$(date --utc +%F)"
if [ "$1" == "--now" ]
then
	TIME="$(date --utc +%F_%H-%M-%S)"
fi


### btrfs FUNCTIONS ###

# Clone subvolume to another location. Useful for copying between disks.
# Usage: clonesub FROM TODIR
# Result: TODIR/PART_OF_FROM_AFTER_SLASH is now a clone of FROM
clonesub() {
	local FROM=$1
	local TODIR=$2
	sudo btrfs send "$FROM" | sudo btrfs receive "$TODIR"
}

# Update existing btrfs clone from newer snapshot version
# Usage: cloneup FROMPARENT FROMNEW TODIR
# Assumption: TODIR/PART_OF_FROMPARENT_AFTER_SLASH is already a clone of FROMPARENT
# Result: TODIR/PART_OF_FROMNEW_AFTER_SLASH is a clone of FROMNEW
cloneup() {
	local FROMPARENT=$1
	local FROMNEW=$2
	local TODIR=$3
	sudo btrfs send -p "$FROMPARENT" "$FROMNEW" | sudo btrfs receive "$TODIR"
}

# Sync, then do "btrfs filesystem sync" for both INTSNAPDIR and EXTSNAPDIR.
# It's called "syncem" as a contraction of "sync them", since it syncs more than one thing, i.e., "them".
# This is important after doing at least some btrfs snapshot operations.
syncem() {
	# the wiki lists sync as part of its snapshot cloning steps, but i think "btrfs filesystem sync" might also be in order
	sync
	btrfs filesystem sync "$INTROOT" > /dev/null
	if [ -n "$EXTSNAPDIR" ]
	then
		btrfs filesystem sync "$EXTSNAPDIR" > /dev/null
	fi
}


### SNAPSHOTTING FUNCTIONS ###

# Bootstrap initial external snapshot clone of VOL.
# Usage: bootstrap VOL
bootstrap() {
	local VOL=$1
	
	# The tr bit converts slashes to dashes so it's a valid folder name.
	local FROM="$INTSNAPDIR/$(timedvol "$VOL")"
	local TO="$EXTSNAPDIR/$(san "$VOL")"
	clonesub "$FROM" "$TO"
}

# Incrementally update external snapshot of VOL.
# Usage: incremental VOL OLDTIME
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

# Make an internal snapshot.
# Usage: internal VOL
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


### UTILITY FUNCTIONS ###

# Get name of X_LASTBAK file for location and VOL, where "X_" is "INT" or "EXT".
# Usage: X_LASTBAK="$(lastbak VOL X_SNAPDIR)"
lastbak() {
	local VOL=$(san "$1")
	local SNAPDIR=$2
	echo -n "$SNAPDIR/$VOL/lastbak"
}

# Sanitize a volume's name for a snapshot folder name.
# Usage: VAR="$(san "$VOL")
san() {
	echo -n "$1" | tr / -
}

# Keep sudo from timing out.
# Usage: sudo -v; sudonotimeout &; CHILDPID=$!; stuff; kill $CHILDPID
sudonotimeout() {
	while true
	do
		sudo -v
		sleep 50 # a short enough time that even if heavy i/o is slowing things down and credential-caching is set for the minimum time, this will still work.
	done
}

# Get time-including name for snapshot, complete with sanitized VOL.
# Usage: VAR="$(timedvol "$VOL")"
# Note: This uses the global TIME var so the caller doesn't have to.
timedvol() {
	local VOL=$(san "$1")
	echo -n "$VOL/$TIME"
}

# Ensure that the directory for VOL exists in INTSNAPDIR, and also for EXTSNAPDIR if the external drive is available.
# Usage: voldir VOL
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


### MAIN STUFF ###

# make sure sudo doesn't time out -- make sure to kill this later
echo "Obtaining sudo privilege"
sudo -v
sudonotimeout &
CHILDPID=$!

for VOL in $VOLS
do
	# Set up directories for the next stuff.
	voldir "$VOL"
	
	# Set up internal snapshot, ensuring it's from today
	INTLASTBAK="$(lastbak "$VOL" "$INTSNAPDIR")"
	if [ ! -e "$INTLASTBAK" ] || [ "$(cat "$INTLASTBAK")" != "$TIME" ]
	then
		internal "$VOL"
		# using tee and ignoring its standard output as a workaround for the lack of a simpler "pipe" command with which to pipe things under sudo
		echo -n "$TIME" | sudo tee "$INTLASTBAK" > /dev/null
	fi
	
	# Check if we should do this next part
	if [ -z "$EXTSNAPDIR" ]
	then
		continue
	fi
	
	# Set up external snapshot
	EXTLASTBAK="$(lastbak "$VOL" "$EXTSNAPDIR")"
	if [ ! -e "$EXTLASTBAK" ]
	then
		bootstrap "$VOL"
		echo -n "$TIME" > "$EXTLASTBAK"
	else
		OLDEXTTIME="$(cat "$EXTLASTBAK")"
		if [ "$OLDEXTTIME" != "$TIME" ]
		then
			incremental "$VOL" "$OLDEXTTIME"
			echo -n "$TIME" > "$EXTLASTBAK"
		fi
	fi
done

# kill sudo-refreshing loop
kill "$CHILDPID"

exit
