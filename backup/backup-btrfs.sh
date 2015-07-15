#!/bin/bash
##
# btrfsbackup.sh
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
if ! which btrfs get-config > /dev/null; then
    echo "Error: Could not find all necessary commands."
    exit 1
fi


### get configuration, exiting on error ###

# Shortcut function to get a config with description, exiting on fail.
_script_name="backup-btrfs"
get() {
    local var_name="$1"
    local cfg_name="$2"
    local cfg_desc="$3"
    local result
    result="$(get-config "$_script_name/$cfg_name" -what-do "$cfg_desc")"
    if [ $? != "0" ]; then
        echo "Error getting config $cfg_name. Exiting." >&2
        exit 1
    else
        # Save config to variable.
        eval "$var_name='$result'"
    fi
}
get internal_root "internal-root" \
    "where btrfs partition's root is mounted"
get internal_snapshot_dir "internal-snapshot-directory" \
    "internal snapshot directory, relative to internal-root"
internal_snapshot_dir="$internal_root/$internal_snapshot_dir"
get externs "external-roots" "list of external backup drive locations"
get vols "subvolumes" "list of subvolumes that should be snapshotted"


### derived global variables ###

# where to make/find/update external snapshot clones
IFS=$'\n'
for external_root in $externs; do
    if [ -d "$external_root" ]; then
	# backup to the root of the external drive.
	external_snapshot_dir="$external_root"
    fi
done
if [ -z "$external_snapshot_dir" ]; then
    echo "External drive not found. Only doing internal snapshotting."
fi

# time to use in naming snapshot directories
time="$(date --utc +%F)"
if [ "$1" == "--now" ]; then
    time="$(date --utc +%F_%H-%M-%S)"
fi


### btrfs functions ###

## Usage: clone-sub from-snap to-dir
# Clone subvolume at from-snap to same-named snapshot in
# to-dir. Useful for copying between disks.
##
# Result: to-dir/part_of_from-snap_after_slash is now a clone of
# from-snap
clone-sub() {
    local from=$1
    local to_dir=$2
    sudo btrfs send "$from" | sudo btrfs receive "$to_dir"
}

## Usage: clone-up from-parent from-new to-dir
# Update existing btrfs clone from newer snapshot version.
##
# Assumption: to-dir/part_of_from-parent_after_slash is already a
# clone of from-parent
##
# Result: to-dir/part_of_from-new_after_slash is a clone of from-new
clone-up() {
    local from_parent=$1
    local from_new=$2
    local to_dir=$3
    sudo btrfs send -p "$from_parent" "$from_new" | sudo btrfs receive "$to_dir"
}

## Usage: sync-em
# Sync, then do "btrfs filesystem sync" for both internal_snapshot_dir
# and external_snapshot_dir.  It's called "sync-em" as a contraction
# of "sync them", since it syncs more than one thing, i.e., "them".
# This is important after doing at least some btrfs snapshot
# operations.
sync-em() {
    # The wiki lists sync as part of its snapshot cloning steps, but I
    # think "btrfs filesystem sync" might also be in order.
    sync
    btrfs filesystem sync "$internal_root" > /dev/null
    if [ -n "$external_snapshot_dir" ]; then
	btrfs filesystem sync "$external_snapshot_dir" > /dev/null
    fi
}


### snapshotting functions ###

## Usage: bootstrap volume
# Bootstrap initial external snapshot clone of volume.
bootstrap() {
    local vol=$1
    
    # The tr bit converts slashes to dashes so it's a valid folder name.
    local from="$internal_snapshot_dir/$(timed-vol "$vol")"
    local to="$external_snapshot_dir/$(sanitize "$vol")"
    clone-sub "$from" "$to"
}

## Usage: incremental volume old-time
# Incrementally update external snapshot of volume.
incremental() {
    local vol=$1
    local old_time=$2
    # no new_time, since that's gotten via timed-vol()
    
    # The tr bit converts slashes to dashes so it's a valid folder name.
    local old="$internal_snapshot_dir/$(sanitize "$vol")/$old_time"
    local from="$internal_snapshot_dir/$(timed-vol "$vol")"
    local to="$external_snapshot_dir/$(sanitize "$vol")"
    sudo btrfs send -p "$old" "$from" | sudo btrfs receive "$to"
}

## Usage: internal volume
# Make an internal snapshot of volume.
internal() {
    local vol=$1
    
    # The tr bit converts slashes to dashes so it's a valid folder name.
    local from="$internal_root/$vol"
    local to="$internal_snapshot_dir/$(timed-vol "$vol")"
    # The btrfs tool already explains what's happening.
    # "-r" is for readonly so it can be used for cloning.
    sudo btrfs subvolume snapshot -r "$from" "$to"
    
    # Make sure snapshot creation is fully propagated.
    sync-em
}


### utility functions ###

## Usage: last_backup="$(last-backup-name volume snap-dir)"
# Get name of last backup for volume in snap-dir, or empty string if
# there is no backup.
last-backup-name() {
    local vol=$(sanitize "$1")
    local snap_dir=$2
    local dir="$snap_dir/$vol"
    # NOTE: This assumes that the snapshot directory is empty iff
    # backups have been made with this script before.
    if [ -n "$(ls "$dir")" ]; then
	# get list of existing snapshots, get last one, and remove leading './'
	cd "$dir" # make the leading part of find's results a deterministic "./"
	find . -maxdepth 1 -mindepth 1 | sort | tail -n 1 | cut -c3-
    fi
}

## Usage: sanitized="$(sanitize volume)"
# Sanitize volume's name to be a suitable snapshot folder name.
sanitize() {
    echo -n "$1" | tr / -
}

## Usage: start-sudo; stuff; stop-sudo
# Activates sudo mode, starts a sudo-refreshing loop, saves the loop's
# process number to $sudo_pid, and sets a trap to stop the loop when
# the script exits (e.g., from the user pressing ^C).
##
# Note: Failure to run stop-sudo after running this may leave a stray
# sudo-refreshing process running. I'm don't really understand on
# which signals `trap` should activate stop-sudo
start-sudo() {
    sudo -v
    ( while true; do sudo -v; sleep 50; done; ) &
    sudo_pid="$!"
    trap stop-sudo SIGINT SIGTERM
}

## Usage: stop-sudo
# Kills the sudo-refreshing loop and cancels the ^C trap.
stop-sudo() {
    kill "$sudo_pid"
    trap - SIGINT SIGTERM
}

## Usage: time_including_volume_path="$(timed-vol volume)"
# Get time-including name for volume's latest snapshot, complete with
# sanitized volume name.
##
# Note: This uses the global time var so the caller doesn't have to.
timed-vol() {
    local vol=$(sanitize "$1")
    echo -n "$vol/$time"
}

## Usage: volume-dir volume
# Ensure that the directory for volume exists in
# $internal_snapshot_dir, and also for $external_snapshot_dir if the
# external drive is available.
volume-dir() {
    local vol=$(sanitize "$1")
    sudo mkdir -p "$internal_snapshot_dir/$vol"
    if [ -n "$external_snapshot_dir" ]; then
	mkdir -p "$external_snapshot_dir/$vol"
    fi
}


### main stuff ###

# Make sure sudo doesn't time out.
echo "Obtaining sudo privilege"
start-sudo # Note: Make sure to run stop-sudo later to kill the loop.

for vol in $vols; do
    # Set up directories for the next stuff.
    volume-dir "$vol"

    # Set up internal snapshot, ensuring that it's from today.
    int_last_backup_name="$(last-backup-name "$vol" "$internal_snapshot_dir")"
    if [ "$int_last_backup_name" != "$time" ]; then
	internal "$vol"
    else
	echo "There's already a snapshot from $time for $vol"
    fi

    # Skip external snapshotting if the directory couldn't be found.
    if [ -z "$external_snapshot_dir" ]; then
	continue
    fi

    # Set up external snapshot, making sure we end up with a clone of
    # the most recent internal snapshot.
    external_last_backup_name="$(last-backup-name "$vol" "$external_snapshot_dir")"
    if [ -z "$external_last_backup_name" ]; then
	bootstrap "$vol"
    else
	if [ "$external_last_backup_name" != "$time" ]; then
	    incremental "$vol" "$external_last_backup_name"
	else
	    echo "There's already a backup from $time for $vol."
	fi
    fi
done

# Cleanup forked subshell and exit.
echo "Killing sudo refresher before exiting."
stop-sudo
exit
