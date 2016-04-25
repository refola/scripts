#!/bin/bash
##
# backup-btrfs.sh
##
# This script snapshots btrfs subvolumes and (incrementally) clones
# them to other drives.
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
# correctly (assuming you're not using '-' in your subvolume names in
# a conflicting way). Within a subvolume's snapshot folder are the
# actual snapshots, which are named by the ISO-8601-formatted UTC time
# of script invocation, to 1-second precision, as given by the command
# 'date --utc --iso-8601=seconds'.

# On backup filesystems, snapshots are cloned with the same structure
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


### generic utility functions ###

# list of commands to run on exit
exit_traps=()
## Usage: trap run-exit-traps EXIT
# Run everything in ${exit_traps[@]}.
run-exit-traps() {
    local i
    for i in "${exit_traps[@]}"; do
        eval "$i"
    done
}
trap run-exit-traps EXIT # Might only work on Linux+Bash.

## Usage: add-exit-trap "command1 [arg1 ...]" ...
# Adds given command(s) to the list of things to run on script exit.
add-exit-trap() {
    exit_traps+=("$@")
}

## Usage: msg text to display
# Outputs a message with a bit of formatting. This should be used
# instead of echo almost everywhere in this script.
msg() {
    echo -e "\e[1m$*\e[0m"
}

## Usage: fatal message about fatal error
# Outputs the given error message, with a bit of formatting, to
# stderr, and then exits the script.
fatal() {
    echo -e "\e[31mError:\e[0;1m $*\e[0m" >&2
    exit 1
}

## Usage: cmd command [args ...]
# Outputs and runs the given command with the given args, prefixit the
# whole thing with sudo. Every simple system-changing command in this
# script should be ran via cmd. Use 'cmd-eval' if you need shell
# features like unix pipes.
cmd() {
    msg "\e[33msudo $*"
    sudo "$@"
}

## Usage: cmd-eval "string to evaluate" [...]
# Outputs and evals the given string. This is the less-automatic
# variant of cmd, intended for cases where things like unix pipes are
# required.
##
# NOTE: You need to manually add "sudo" to commands ran with this.
cmd-eval() {
    msg "\e[33m$*"
    eval "$*"
}


### btrfs utility functions ###

## Usage: last_backup_time="$(last-backup backup-dir)"
# Get name of last backup in given backup directory, or empty string
# if there is no backup.
last-backup() {
    local dir="$1"
    # NOTE: This assumes that this script is the only source of items
    # in the snapshot directory.
    if [ -n "$(ls "$dir")" ]; then
        # Get list of existing snapshots and get last one.
        local last="$(find "$dir" -maxdepth 1 -mindepth 1 | sort | tail -n1)"
        # Get rid of leading */ and output it.
        echo "${last/*\//}"
    fi
}

## Usage: sanitized="$(sanitize subvolume)"
# Sanitize a btrfs subvolume's name by turning each '/' into a '-'.
sanitize() {
    echo -n "$1" | tr / -
}


### btrfs actions ###

## Usage: clone-or-update from-snap to-dir
# Use appropriate btrfs commands to make it so that to-dir contains a
# copy of the btrfs subvolume at from-snap.
##
# Result: to-dir/part_of_from-snap_after_slash matches from-snap.
clone-or-update() {
    local from="$1"
    local to_dir="$2"
    local from_dir="$(dirname "$from")"
    local last_parent_name="$(last-backup "$to_dir")"

    if [ -z "$last_parent_name" ]; then # No subvol's found, so bootstrap.
        msg "Cloning '$from'→'$to_dir'"
        cmd-eval "sudo btrfs send '$from' | sudo btrfs receive '$to_dir'"
    else
        last_parent="$from_dir/$last_parent_name"
        msg "Using mutual parent '$last_parent' to clone '$from'→'$to_dir'"
        cmd-eval "sudo btrfs send -p '$last_parent' '$from' | sudo btrfs receive '$to_dir'"
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
    # It's necessary to sync after snapshotting so that 'btrfs send'
    # works correctly. See:
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
    # Get variables.
    local action="$1"
    local from="$2"
    local to="$3"
    shift 3
    local subvols=("$@")
    # Verify action validity.
    if [ "$action" != "snapshot" ] && [ "$action" != "copy-latest" ]; then
        fatal "Invalid snap action: '$action'"
    fi
    # Check if the origin and destination are there.
    if [ ! -d "$from" ] || [ ! -d "$to" ]; then
        msg "\e[32mMissing origin/destination for '$from'→'$to', so skipping it."
        return
    else
        msg "\e[32mRunning '$action' for '$from'→'$to'."
    fi
    # Loop through all subvolumes.
    local sv
    for sv in "${subvols[@]}"; do
        local sanSv="$(sanitize "$sv")"
        # Make sure the destination directory exists.
        if [ ! -d "$to/$sanSv" ]; then
            cmd mkdir "$to/$sanSv" # No '-p': $to must already exist.
        fi
        # Do the applicable action.
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
    # Another copy of the script's probably running. Exit with error.
    fatal "Could not acquire lock: $lockdir"
fi

# Make sure sudo doesn't time out.
msg "Enabling sudo mode."
cmd sudo -v # Activate.
( while true; do sudo -v; sleep 50; done; ) & # Keep it running.
add-exit-trap "kill $!" # Make sure it stops with the script.

# Get timestamp for new snapshots.
timestamp="$(date --utc --iso-8601=seconds)"


### main stuff ###

# TODO: Rewrite to use command line arguments: backup, install, uninstall

config_use="List of commands to run for backup-btrfs. This is actually
a mini script used to control whach backup-btrfs does. It works by
calling the 'make-snaps' and 'copy-latest' functions with the desired
arguments. Each of these functions works as follows:

function origin destination subvolumes ...

Snapshot or clone given subvolumes from 'origin' to 'destination'.

The only difference is that 'make-snaps' makes snapshots within a
drive and 'copy-latest' copies the (latest) snapshot of each subvolume
to another drive.

If any of this is confusing, please choose to edit the default config.
It is a good and nicely-commented example."

old_IFS="$IFS" # Save old IFS.
IFS=$'\n' # Separate control script by line.
config=( $(get-config backup-btrfs/control_script -what-do\
                      "$config_use" -verbatim) )
IFS="$old_IFS" # Go back to normal IFS.
for line in "${config[@]}"; do
    eval "$line"
done
