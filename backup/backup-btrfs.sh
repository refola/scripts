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
# Outputs and runs the given command with the given args, prefixing
# the whole thing with sudo. Every simple system-changing command in
# this script should be ran via cmd. Use 'cmd-eval' if you need shell
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

## Usage: del-older-than location timestamp
# Deletes each btrfs subvolume at 'location' that is older than
# 'timestamp'. This is useful for deleting old snapshot archives to
# free up space.
del-older-than() {
    local location="$1"
    local timestamp="$2"
    local maybe_older
    for maybe_older in "$location"/*; do
        if [[ "$maybe_older" < "$location/$timestamp" ]]; then
            msg "Deleting old subvolume '$maybe_older'."
            cmd btrfs subvolume delete "$maybe_older"
        fi
    done
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
    if ! echo snapshot copy-del copy-latest | grep -q "$action"; then
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
                clone-or-update "$from/$sanSv/$timestamp" "$to/$sanSv" ||\
                    fatal "Error updating $sv."
                ;;
            "copy-del")
                clone-or-update "$from/$sanSv/$timestamp" "$to/$sanSv" ||\
                    fatal "Error updating $sv. Not deleting old snapshots."
                del-older-than "$from/$sanSv" "$timestamp"
                ;;
            "snapshot")
                snapshot "$from/$sv" "$to/$sanSv/$timestamp"
                ;;
            *) # Error...
                fatal "Invalid action '$action' snuck through check."
                ;;
        esac
    done
    echo
}

## Usage: make-snaps from to subvolume [...]
# Make a read-only btrfs snapshot at 'to' for each given subvolume in
# 'from'. This is directly useful for "temporal" backups, and the
# snapshots are useful for (incrementally) copying subvolumes to other
# devices for real backups.
make-snaps() {
    snap snapshot "$@"
}

## Usage: copy-latest from to subvolume [...]
# Copy the latest snapshot for each given subvolume in 'from' to
# 'to'. This is useful for real backups, (incrementally) copying
# entire subvolumes between devices.
copy-latest() {
    snap copy-latest "$@"
}

## Usage: copy-latest-and-delete-origins-parent-subvolumes from to subvolume [...]
# Copy the latest snapshot for each given subvolume in 'from' to 'to',
# and then delete the found parent subvolume from 'from'. This is
# useful when the device for 'from' doesn't have much space and the
# device for 'to' acts as an archive of the old states of 'from'.
copy-latest-and-delete-origins-parent-snapshots() {
    snap copy-del "$@"
}


### initial checks and setup ###

## Usage: init
# Runs initialization for the script. This should only be used by
# main(), and only once.
init() {
    # Check that required programs are installed.
    if ! which btrfs > /dev/null; then
        fatal "btrfs command not found. Are you sure you're using btrfs?"
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
    cmd -v # Activate.

    # This loop repeatedly runs "sudo -v" to keep sudo from timing
    # out, enabling the script to continue as long as necessary,
    # without post-startup interaction.
    ( while true; do cmd -v; sleep 50; done; ) &
    add-exit-trap "kill $!" # Make sure it stops with the script.

    # Get timestamp for new snapshots.
    timestamp="$(date --utc --iso-8601=seconds)"
}


### main stuff ###

## Usage: config_path="$(get-config-path)"
# Gets the path to the script's config.
get-config-path() {
    get-config backup-btrfs/control_script -path
}

## Usage: check-config
# Checks that the config exists, exiting the script with a fatal error
# if not.
check-config() {
    get-config backup-btrfs/control_script -what-do\
               "$config_use" >/dev/null || fatal "Can't get config!"
}

# This explains how the config file works.
config_use="List of commands to run for backup-btrfs. This is actually
a mini script used to control what backup-btrfs does. It works by
calling the 'make-snaps' and 'copy-latest' functions with the desired
arguments. Each of these functions works as follows:

function origin destination subvolumes ...

Snapshot or clone given subvolumes from 'origin' to 'destination'.

The only difference is that 'make-snaps' makes snapshots within a
drive and 'copy-latest' copies the (latest) snapshot of each subvolume
to another drive.

If any of this is confusing, please choose to edit the default config.
It is a good and nicely-commented example."
## Usage: backup
# Gets the backup config and runs it to do backups.
backup() {
    msg "Running backups."
    check-config # Don't try running an imaginary config.
    # Source the config script to run it.
    ## TODO: Wait for <1> to be fixed so this works regardless of
    ## where ShellCheck is ran from.
    ### <1>: https://github.com/koalaman/shellcheck/issues/539
    # shellcheck source=../config/backup-btrfs/control_script
    . "$(get-config-path)"
}

install_path="/sbin/backup-btrfs.installed"
systemd_install_dir="/etc/systemd/system"
# Yes, ShellCheck, I know where this string ends.
# shellcheck disable=SC1078,SC1079
autogen_warn_msg="## DO NOT EDIT THIS AUTOGENERATED FILE!
# This file was made via 'backup-btrfs install'. If you want to change
# it, then make the appropriate change in your own config (and/or
# the script itself) and run 'backup-btrfs reinstall'."$'\n'$'\n'$'\n'

## Usage: install
# Makes sure there's a valid config, copies this to $install_path, and
# sets a systemd service/timer pair to automatically run this every
# hour or so.
install() {
    msg "Installing script as system command."

    # Make sure the config exists.
    check-config

    # Read in every line of this script, stopping at the line that
    # says "### main stuff ###".
    local stop_at="### main stuff ###"
    local script=
    while IFS= read -r; do
        if [ "$REPLY" = "$stop_at" ]; then
            break
        elif [ -z "$script" ]; then
            script="$REPLY"$'\n'"$autogen_warn_msg"
        else
            script="$script"$'\n'"$REPLY"
        fi
    done < "$(readlink -f "$0")" # $0 is fragile, but needed

    # Append init-running.
    script="$script"$'\n'"init # Run init manually; this has no main."

    # Append config.
    script="$script"$'\n'"### config from install time ###"
    script="$script"$'\n'"$(cat "$(get-config-path)")"

    # Save to $install_path
    tmp_path="/tmp/backup-btrfs.sh_temp_backup-btrfs.installed"
    msg "echo \"\$script\" > \"$tmp_path\""
    echo "$script" > "$tmp_path"
    cmd cp "$tmp_path" "$install_path"
    cmd chmod +x "$install_path"
    cmd rm "$tmp_path"

    # Copy systemd units.
    local from="$(get-data backup-btrfs -path)"
    cmd cp "$from/backup-btrfs.service" "$systemd_install_dir"
    cmd cp "$from/backup-btrfs.timer" "$systemd_install_dir"

    # Enable and start systemd service+timer pair.
    cmd systemctl enable backup-btrfs.service
    cmd systemctl enable backup-btrfs.timer
    cmd systemctl start backup-btrfs.timer

    # Tell user it's been installed.
    msg "Install complete! Here are the systemd timers to confirm."
    cmd systemctl list-timers
}
## Usage: reinstall
# Uninstall and reinstall the script from the system.
reinstall() {
    msg "Reinstalling with latest config and script version."
    uninstall
    install
}
## Usage: uninstall
# Remove from $install_path and undo systemd changes.
uninstall() {
    msg "Uninstalling script."

    # Stop and disable systemd service+timer pair.
    cmd systemctl stop backup-btrfs.timer
    cmd systemctl disable backup-btrfs.timer
    cmd systemctl disable backup-btrfs.service

    # Remove systemd units.
    cmd rm "$systemd_install_dir/backup-btrfs.timer"
    cmd rm "$systemd_install_dir/backup-btrfs.service"

    # Remove from $install_path.
    cmd rm "$install_path"

    # Tell user it's been removed.
    msg "Uninstall complete."
}

usage="Usage: backup-btrfs action

Run btrfs backups. Here are the valid actions.

backup     Run btrfs backups according to config.
install    Bundle script and config into no-arg system script and set
           systemd to automatically run it every hour or so.
reinstall  Redo install with latest script and config versions.
uninstall  Remove installed file and systemd units.
usage      Show this usage information.
"
## Usage: usage
# Show usage message.
usage() {
    msg "$usage"
}

## Usage: main "$@"
# Run the script.
main() {
    if [ $# != '1' ]; then
        usage
        fatal "Expected exectly 1 argument."
    fi

    case "$1" in
        backup|install|reinstall|uninstall)
            init
            $1 ;;
        usage) usage ;;
        *) usage
           fatal "Unknown action: '$1'." ;;
    esac
}

main "$@"
