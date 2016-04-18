#!/bin/bash
##
# backup-btrfs2.sh # TODO: rename to replace backup-btrfs.sh after
# this is mature.
##
# This is a rewrite of backup-btrfs.sh, intended to be more-easily
# composable for more-complex btrfs snapshot/backup goals. In
# particular, it now has decoupled supports two btrfs uses: making
# snapshots within a filesystem and efficiently transferring the
# snapshots to another filesystem.
##
# Please check out this link for underlying btrfs commands used and
# alternative btrfs backup scripts (which are probably more-advanced
# and useful than this one):
# https://btrfs.wiki.kernel.org/index.php/Incremental_Backup
##


### limitations ###

# This script assumes that you mostly just want the latest data. It
# does not backup older snapshots.

# This script uses 1-second time granularity, so new snapshots are
# "always" made (the exception being if this script on somehow
# finishes in under a second on your system).

# This does not delete old snapshots. You'll need to (manually) delete
# them before drive space fills up (e.g., with 'btrfs sub del
# /path/to/snapshots/2016-01-02-*' for deleting all snapshots from
# 2016, January 2nd).


### filesystem layout ###

# The original subvolumes can be anywhere under the respective btrfs root.

# Snapshots are stored within the btrfs root in folders named after
# the subvolumes, with '@' converted to '-' so nested subvolumes work
# correctly (hopefully you're not using '-' in your subvolume names in
# a conflicting way). Within a subvolume's snapshot folder are the
# actual snapshots, which are named by the ISO-8601-formatted UTC time
# of script invocation, to second precision, as given by the command
# 'date --utc --iso-8601=seconds'.

# On backup filesydstems, snapshots are cloned with the same structure
# as the snapshots directory.

# Example: Suppose you have subvolumes @distro, @home, and @home/user
# in your main btrfs volume mounted at /root; you want to store
# snapshots under @snapshots; and you want to backup snapshots to
# /backup. Then the layout will look something like this, with more
# timestamped snapshots appearing over time:
## Original subvolume paths:
# /root/@distro
# /root/@home
# /root/@home/user
## Snapshot paths (assuming you ran this script at the respective times):
# /root/@snapshots/@distro/2016-03-31T16:43:13+00:00
# /root/@snapshots/@distro/2016-04-17T23:53:47+00:00
# /root/@snapshots/@distro/2016-04-18T01:24:20+00:00
# /root/@snapshots/@home/2016-03-31T16:43:13+00:00
# /root/@snapshots/@home/2016-04-17T23:53:47+00:00
# /root/@snapshots/@home/2016-04-18T01:24:20+00:00
# /root/@snapshots/@home-user/2016-03-31T16:43:13+00:00
# /root/@snapshots/@home-user/2016-04-17T23:53:47+00:00
# /root/@snapshots/@home-user/2016-04-18T01:24:20+00:00
## Backup paths (assuming the backup drive wasn't available when the
## 2016-04-17 snapshots were made):
# /backup/@distro/2016-03-31T16:43:13+00:00
# /backup/@distro/2016-04-18T01:24:20+00:00
# /backup/@home/2016-03-31T16:43:13+00:00
# /backup/@home/2016-04-18T01:24:20+00:00
# /backup/@home-user/2016-03-31T16:43:13+00:00
# /backup/@home-user/2016-04-18T01:24:20+00:00


### super-top-level utility functions ###

# exit trap setup
exit_traps=()
run-exit-traps() {
    local i
    for i in "${exit_traps[@]}"; do
        eval "$i"
    done
}
# Trapping only on EXIT might not be portable across shells and
# unices, but btrfs is Linux-only and the shebang at the top of this
# script ensures it's Bash.
trap run-exit-traps EXIT

## Usage: add-exit-trap "quoted commands" "to run with args"
# Adds a command to the list of things to run on script exit.
add-exit-trap() {
    exit_traps+=("$@")
}

## Usage: msg things to show the user
# Outputs a message with a bit of formatting. This should be used
# instead of echo almost everywhere in this script.
msg() {
    echo -e "\e[1m$*\e[0m"
}

## Usage: fatal message about fatal error
# Outputs the given error message, with a bit of formatting, to
# stderr, and then exits the script.
fatal() {
    echo -e "\e[31mError:\e[0;1m $*\e[0m"
    exit 1
}

## Usage: cmd command [args ...]
# Outputs and runs the given command with the given args, prefixit the
# whole thing with sudo. Every simple system-changing command in this
# script should be ran via cmd. Use 'cmd-eval' if you need shell
# features like unix pipes.
cmd() {
    msg "\e[33msudo $*"
    ## TODO: uncomment this after checking that everything looks good.
    #sudo "$@"
}

## Usage: cmd-eval "string to evaluate" [...]
# Outputs and evals the given string. This is the less-automatic
# variant of cmd, intended for cases where things like unix pipes are
# required.
cmd-eval() {
    msg "\e[33m$*"
    ## TODO: uncomment this after checking that everything looks good.
    # eval "$*"
}


### not-so-super-top-level utility functions ###

## Usage: last_backup="$(last-backup backup-dir)"
# Get name of last backup in given backup directory, or empty string
# if there is no backup.
last-backup() {
    local dir="$1"
    # NOTE: This assumes that this script is the only source of items
    # in the snapshot directory
    if [ -n "$(ls "$dir")" ]; then
        # get list of existing snapshots and get last one
        local last="$(find "$dir" -maxdepth 1 -mindepth 1 | sort | tail -n1)"
        # get rid of leading */ and output it
        echo "${last/*\//}"
    fi
}

## Usage: sanitized="$(sanitize volume)"
# Sanitize volume's name by turning each '/' into a '-', resulting in
# a valid folder name.
sanitize() {
    echo -n "$1" | tr / -
}


### basic btrfs functions ###

## Usage: clone-or-update from-snap to-dir
# Use appropriate btrfs commands to make it so that to-dir contains a
# copy of the btrfs subvolume at from-snap.
##
# Result: to-dir/part_of_from-snap_after_slash matches from-snap.
clone-or-update() {
    local from="$1"
    local to_dir="$2"
    local from_dir="$(dirname "$from")"
    local last_parent="$from_dir/$(last-backup "$to_dir")"

    if [ -z "$last_parent" ]; then
        msg "Cloning '$from'→'$to_dir'"
        cmd-eval "sudo btrfs send '$from' | sudo btrfs receive '$to_dir'"
    else
        msg "Using mutual parent '$last_parent' to clone '$from'→'$to_dir'"
        cmd-eval "sudo btrfs send -p '$last_parent' '$from' | sude btrfs receive '$to_dir'"
    fi
}

## Usage: snapshot from-subvolume to-snapshot-name
# Snapshots from-subvolume to to-snapshot-name and runs 'sync' to
# workaround a bug in btrfs.
snapshot() {
    local from="$1"
    local to="$2"
    msg "Snapshotting '$from'→'$to'"
    cmd btrfs subvolume snapshot -r "$from" "$to"
    # It's currently necessary to sync after snapshotting before using
    # 'btrfs send' for cross-partition snapshot clone/update. See:
    # https://btrfs.wiki.kernel.org/index.php/Incremental_Backup#Initial_Bootstrapping
    sync
}


### high-level snapshot actions ###

## Usage: snap action from to subvolumes ...
# Does the indicated snapshot action with given 'from' and 'to'
# locations and given subvolume(s). Valid actions are "snapshot" and
# "copy-latest", respectively creating snapshots within a partition
# and copying the latest snapshot to another partition.
snap() {
    local action="$1"
    if [ "$action" != "snapshot" ] && [ "$action" != "copy-latest" ]; then
        fatal "Invalid snap action: '$action'"
    fi
    local from="$2"
    local to="$3"
    if [ ! -d "$from" ] || [ ! -d "$to" ]; then
        msg "\e[32mMissing origin/destination for '$from'→'$to', so skipping it."
        return
    else
        msg "\e[32mRunning '$action' for '$from'→'$to'."
    fi
    shift 3
    local subvols=("$@")
    local sv
    for sv in "${subvols[@]}"; do
        local sanSv="$(sanitize "$sv")"
        if [ ! -d "$to/$sanSv" ]; then
            cmd mkdir "$to/$sanSv"
        fi
        case "$action" in
            "copy-latest")
                clone-or-update "$from/$sanSv/$timestamp" "$to/$sanSv" ;;
            "snapshot")
                snapshot "$from/$sv" "$to/$sanSv/$timestamp" ;;
            *) # Error...
                fatal "Invalid action '$action' snuck through check." ;;
        esac
    done
    echo
}

## Usage: make-snaps from to subvolume [...]
# Make a btrfs snapshot at 'to' for each given subvolume in 'from'.
make-snaps() {
    snap snapshot "$@"
}

## Usage: copy-latest from to subvolume [...]
# Copy the latest snapshot(s) for each subvolume in 'from' to 'to'.
copy-latest() {
    snap copy-latest "$@"
}


### initial checks and setup ###

# Check that required programs are installed.
if ! which btrfs get-config > /dev/null; then
    fatal "Could not find needed programs."
fi

# Check lock directory to prevent parallel runs.
lockdir="/tmp/.backup-btrfs.lock"
if cmd mkdir "$lockdir"; then
    # This is the only copy of the script running. Make sure we'll
    # clean up at the end.
    add-exit-trap "cmd rmdir '$lockdir'"
else
    fatal "Could not acquire lock: $lockdir"
fi

# Make sure sudo doesn't time out.
cmd sudo -v # activate
( while true; do cmd sudo -v; sleep 50; done; ) & # keep it running
add-exit-trap "kill $!" # make sure it stops with the script

# Get timestamp for new snapshots.
timestamp="$(date --utc --iso-8601=seconds)"


### main stuff ###

# Still hard-coded, for now...."
ssd_root="/ssd"
ssd_snap_dir="$ssd_root/@snapshots"
ssd_vols=(@chakra @home @home/kelci @home/mark @kubuntu @suse)
hdds_root="/hdds"
hdds_snap_dir="$hdds_root/snapshots"
hdds_vols=(@fedora @shared)
ext_root="/run/media/$USER/OT4P"
hdds_to_ext_vols=("${ssd_vols[@]}" "${hdds_vols[@]}")

make-snaps "$ssd_root" "$ssd_snap_dir" "${ssd_vols[@]}"
copy-latest "$ssd_snap_dir" "$hdds_snap_dir" "${ssd_vols[@]}"
make-snaps "$hdds_root" "$hdds_snap_dir" "${hdds_vols[@]}"
copy-latest "$hdds_snap_dir" "$ext_root" "${hdds_to_ext_vols[@]}"
