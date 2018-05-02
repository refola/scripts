#!/usr/bin/env bash
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


### contents ###

# comments
## header
### shebang
### short description
### note
## contents
### comments
### code
## limitations
### recentism
### time quantization
## filesystem layout
### subvolume locations
### snapshot name format
### backup snapshot clone structure
### example

# code
## global variable declarations
### debug mode
### exit traps
### start time timestamp
### config explanation
### install parameters
### usage
## generic utility functions
### exit traps
### messages
### command-running
### path existence checking
### list formatting
## btrfs utility functions
### last backup name retrieval
### subvolume path-to-name sanitization
## btrfs actions
### snapshot creation
### snapshot clone/update
### old snapshot deletion
## high-level snapshot actions
### subvolume-looping function
### snapshot creation
### snapshot clone/update
### old snapshot deletion
## initial checks and setup
### initialization
## main stuff
### configuration getting
### configuration checking
### configuration running
### systemd service installation
### systemd service reinstallation
### systemd service uninstallation
### usage information
### main


### limitations ###

# This script assumes that you mostly just want the latest data. It
# does not backup older snapshots.

# This script uses 1-second time granularity, so new snapshots are
# "always" made (the exception being if this script on somehow
# finishes in under a second on your system).


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


### global variable declarations ###

# Set by main()
DEBUG= # Disabled (non-blank for enabled)

# Set near run-exit-traps()
EXIT_TRAPS=

# Set by init()
TIMESTAMP=

# Set near check-config()
CONFIG_USE=

# Set near install()
INSTALL_PATH=
SYSTEMD_INSTALL_DIR=
AUTOGEN_WARN_MSG=

# Set near usage()
USAGE=


### generic utility functions ###

# list of commands to run on exit
EXIT_TRAPS=()
## Usage: trap run-exit-traps EXIT
# Run everything in ${exit_traps[@]}.
run-exit-traps() {
    local i
    for i in "${EXIT_TRAPS[@]}"; do
        msg "Running exit trap: $i"
        eval "$i"
    done
}
trap run-exit-traps EXIT # Might only work on Linux+Bash.

## Usage: add-exit-trap "command1 [arg1 ...]" ...
# Adds given command(s) to the list of things to run on script exit.
add-exit-trap() {
    EXIT_TRAPS+=("$@")
}

## Usage: msg "text to display"
# Outputs a message with a bit of formatting. This should be used
# instead of echo almost everywhere in this script.
msg() {
    echo -e "\e[1m$*\e[0m"
}

## Usage: fatal "message about fatal error"
# Outputs the given error message, with a bit of formatting, to
# stderr, and then exits the script.
fatal() {
    echo -e "\e[31mError:\e[0;1m $*\e[0m" >&2
    exit 1
}

## Usage: cmd command [args ...]
# Normally, this runs the given command with the given args, prefixing
# the whole thing with sudo. But if debug mode is active, the command
# is displayed and not ran.
##
# Every simple system-changing command in this script should be ran
# via cmd. Use 'cmd-eval' if you need shell features like unix pipes.
cmd() {
    if [ -n "$DEBUG" ]; then
        msg "\e[33msudo $*"
    else
        sudo "$@"
    fi
}

## Usage: cmd-eval "string to evaluate" [...]
# Normally, this evals the given string. But if debug mode is active,
# the string is displayed and not eval'd.
##
# This is the less-automatic variant of 'cmd', intended for cases
# where things like unix pipes are required.
##
# NOTE: You need to manually add "sudo" to commands ran with this.
cmd-eval() {
    if [ -n "$DEBUG" ]; then
        msg "\e[33m$*"
    else
        eval "$*"
    fi
}

## Usage: exists paths...
# Check if given paths exist, giving a message and returning 1 on
# first non-existent path. Useful for, e.g., "if exists
# /path/to/place; then do-thing; fi".
exists() {
    while [ "$#" -gt 0 ]; do
        if [ ! -e "$1" ]; then
            msg "Not found: $1"
            return 1
        fi
        shift
    done
}

## Usage: list separator last_separator thing1 [thing2 [...]]
# Lists all things, separating them with the given separator,
# switching to last_separator for separating the last two things. Bash
# doesn't support returning strings, so the result is echo'd out and
# probably needs capturing.
list() {
    local sep="$1"
    local last="$2"
    shift 2
    local out
    while [ "$#" -gt "2" ]; do
        out+="$1$sep"
        shift
    done
    if [ "$#" = "2" ]; then
        out+="$1$last"
        shift
    fi
    out+="$1"
    echo "$out"
}


### btrfs utility functions ###

## Usage: last_backup_name="$(last-backup backup-dir)"
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

## Usage: snapshot from-root to-snapshot-dir subvol
# Snapshots from-root/subvol to to-snapshot-dir/subvol/$TIMESTAMP
# (sanitizing subvol and making the directory for the to-snapshot-dir
# side, as applicable) and runs 'sync' to workaround a bug in btrfs.
snapshot() {
    local from_root="$1"
    local to_snap_dir="$2"
    local subvol="$3"
    local sanSv="$(sanitize "$subvol")"
    local from="$from_root/$subvol"
    local to="$to_snap_dir/$sanSv/$TIMESTAMP"
    cmd mkdir -p "$to_snap_dir/$sanSv" # Make sure the target directory exists.
    msg "Snapshotting '$from'→'$to'"
    cmd btrfs subvolume snapshot -r "$from" "$to"
    # It's necessary to sync after snapshotting so that 'btrfs send'
    # works correctly. See:
    # https://btrfs.wiki.kernel.org/index.php/Incremental_Backup#Initial_Bootstrapping
    sync
}

## Usage: clone-or-update from-dir to-dir subvolume
# Use btrfs commands to make it so that to-dir/sanitized-subvolume
# contains a copy of the latest btrfs subvolume at
# from-dir/sanitized-subvolume.
##
# Result: to-dir/sanitized-subvolume/latest-snapshot-date matches
# from-dir/sanitized-subvolume/latest-snapshot-date.
clone-or-update() {
    local from_dir="$1"
    local to_dir="$2"
    local subvol="$3"
    local sanSv="$(sanitize "$subvol")"
    from_dir="$from_dir/$sanSv"
    local last="$(last-backup "$from_dir")"
    if [ -z "$last" ]; then
        msg "Error: No backup in $from_dir"
        return 1
    fi
    local from="$from_dir/$last"
    to_dir="$to_dir/$sanSv"
    cmd mkdir -p "$to_dir" # Make sure the target directory exists.
    local last_parent="$(last-backup "$to_dir")"

    if [ -z "$last_parent" ]; then # No subvols found, so bootstrap.
        msg "Cloning '$from'→'$to_dir'"
        cmd-eval "sudo btrfs send '$from' | sudo btrfs receive '$to_dir'"
    elif [ -e "$to_dir/$last" ]; then # Nothing to do.
        msg "Skipping '$subvol': '$to_dir' already has the latest snapshot from '$from_dir'."
    else # Incremental backup.
        msg "Cloning '$from'→'$to_dir' via parent '$last_parent'."
        cmd-eval "sudo btrfs send -p '$from_dir/$last_parent' '$from' | sudo btrfs receive '$to_dir'"
    fi
}

## Usage: del-older-than location time subvolume
# Deletes each btrfs snapshot for subvolume at 'location' that is
# older than 'time', with age determined by the name of the snapshot,
# expected to be in ISO-8601 format and UTC, as used by the rest of
# this script. This is useful for deleting old snapshot archives to
# free up space.
delete-older-than() {
    local location="$1/$(sanitize "$3")"
    local time="$(date --utc --iso-8601=seconds --date="$2")"
    local maybe_older
    for maybe_older in "$location"/*; do
        if [[ "$maybe_older" < "$location/$time" ]]; then
            msg "Deleting old subvolume '$maybe_older'."
            cmd btrfs subvolume delete "$maybe_older"
        fi
    done
}


### high-level snapshot actions ###

## Usage: subvol-loop function num-fn-args fn-args [...] subvolumes [...]
# Iterates through each subvolume, running the given 'function' with
# its 'fn-args', of which there are 'num-fn-args', appending the
# current subvolume to the end of the arguments for 'function'. This
# abstraction is meant to replace the current 'snap' function.
subvol-loop() {
    # known-location args
    local fn="$1"
    local num_fn_args="$2"
    # known-but-variable-count args
    local fn_args=("${@:3:$num_fn_args}")
    # shift to and save the subvolume list
    shift 2
    shift "$num_fn_args"
    local subvols=("$@")

    # Inform user of what's going on.
    local args
    args="'$(list "', '" "', and '" "${fn_args[@]}")'"
    local svs
    svs="'$(list "', '" "', and '" "${subvols[@]}")'"
    msg "\e[32mRunning '$fn' with args ($args) on subvols ($svs)."

    # Actually run the function for the subvolumes.
    local sv
    for sv in "${subvols[@]}"; do
        # Do the applicable action.
        $fn "${fn_args[@]}" "$sv"
    done
}

## Usage: make-snaps from to subvolume [...]
# Make a read-only btrfs snapshot at 'to' for each given subvolume in
# 'from'. This is directly useful for "temporal" backups, and the
# snapshots are useful for (incrementally) copying subvolumes to other
# devices for real backups.
make-snaps() {
    exists "$1" "$2" || return 1
    subvol-loop snapshot 2 "$@"
}

## Usage: copy-latest from to subvolume [...]
# Copy the latest snapshot for each given subvolume in 'from' to
# 'to'. This is useful for real backups, (incrementally) copying
# entire subvolumes between devices.
copy-latest() {
    exists "$1" "$2" || return 1
    subvol-loop clone-or-update 2 "$@"
}

## Usage: delete-old snap_dir time subvolume [...]
# Delete snapshots older than 'time' from snap_dir. 'time' is a
# date/time string as used by "date --date=STRING". For example, a
# time of "3 days ago" will delete snapshots which are more than 3
# days old. This is useful when the device for 'from' doesn't have
# much space and the device for 'to' acts as an archive of the old
# states of 'from'.
delete-old() {
    exists "$1" || return 1
    subvol-loop delete-older-than 2 "$@"
    # Sync everything to free up cleared space.
    msg "'sync'ing '$1' to free space from deleted snapshots."
    msg "Note that btrfs' cleanup of freed space may take a while longer."
    cmd btrfs filesystem sync "$1"
}


### initial checks and setup ###

## Usage: init
# Runs initialization for the script. This should be called by main()
# and only main(), once and only once.
init() {
    # Warn about debug mode if active
    if [ -n "$DEBUG" ]; then
        msg "Debug mode active. Essential root commands will not really be ran."
    fi

    # Check that required programs are installed.
    if ! which btrfs > /dev/null; then
        fatal "btrfs command not found. Are you sure you're using btrfs?"
    fi

    # Check lock directory to prevent parallel runs.
    local lockdir="/tmp/.backup-btrfs.lock"
    msg "Acquiring lock as root."
    if cmd mkdir "$lockdir"; then
        # This is the only copy of the script running. Make sure we'll
        # clean up at the end.
        add-exit-trap "cmd rmdir '$lockdir'"
    else
        # Another copy of the script's probably running. Exit with error.
        fatal "Could not acquire lock: $lockdir"
    fi

    # This loop repeatedly runs "sudo -v" to keep sudo from timing
    # out, enabling the script to continue as long as necessary,
    # without pausing for credentials.
    ##
    # Note: It's not necessary to explicitly activate sudo mode first,
    # since the lock acquisition already uses sudo.
    msg "Starting sudo-refreshing loop."
    ( while true; do sleep 50; cmd -v; done; ) &
    add-exit-trap "kill $! # sudo-refreshing loop"

    # Get timestamp for new snapshots.
    TIMESTAMP="$(date --utc --iso-8601=seconds)"
}


### main stuff ###

## Usage: config_path="$(get-config-path)"
# Gets the path to the script's config.
get-config-path() {
    get-config backup-btrfs/control_script -path
}

# This explains how the config file works.
CONFIG_USE="List of commands to run for backup-btrfs. This is actually a mini
script used to control what backup-btrfs does. It works by calling the
'make-snaps', 'copy-latest', and 'delete-old' functions with the
desired arguments. Each of these functions works as follows:

function origin destination subvolumes ...

Snapshot or clone given subvolumes from 'origin' to 'destination'.

The only difference is that 'make-snaps' makes snapshots within a
drive and 'copy-latest' copies the (latest) snapshot of each subvolume
to another drive.

If any of this is confusing, please choose to edit the default config.
It is a good and nicely-commented example."

## Usage: check-config
# Checks that the config exists, exiting the script with a fatal error
# if not.
check-config() {
    # Check the config, explaining how it works if it isn't already set.
    get-config backup-btrfs/control_script -verbatim -what-do\
               "$CONFIG_USE" >/dev/null || fatal "Can't get config!"
}

## Usage: backup
# Gets the backup config and runs it to do backups.
backup() {
    msg "Running backups."
    check-config # Don't try running an imaginary config.
    # Source the config script to run it.
    ## TODO: Wait for <1> to be fixed so the following "shellcheck
    ## source" line works regardless of where ShellCheck is ran from.
    ### <1>: https://github.com/koalaman/shellcheck/issues/539
    # shellcheck source=../config/backup-btrfs/control_script
    . "$(get-config-path)"
}

INSTALL_PATH="/sbin/backup-btrfs.installed"
SYSTEMD_INSTALL_DIR="/etc/systemd/system"
# Yes, ShellCheck, I know where this string ends.
# shellcheck disable=SC1078,SC1079
AUTOGEN_WARN_MSG="## DO NOT EDIT THIS AUTOGENERATED FILE!
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
            # REPLY="#!/bin/bash"
            script="$REPLY"$'\n'"$AUTOGEN_WARN_MSG"
        else
            script="$script"$'\n'"$REPLY"
        fi
    done < "$(readlink -f "$0")" # $0 is fragile, but needed

    # Append function-wrapped config.
    script="$script"$'\n'"### config from install time, wrapped in function ###"
    script="$script"$'\n'"backup() {"
    script="$script"$'\n'"msg 'Running backups.'"
    script="$script"$'\n'"$(cat "$(get-config-path)")"
    script="$script"$'\n'"}"

    # Append init-running and backup-running.
    script="$script"$'\n'"init # Run init manually; this has no main."
    script="$script"$'\n'"backup # Run backup manually; this has no main."

    # Save to $install_path
    tmp_path="/tmp/backup-btrfs.sh_temp_backup-btrfs.installed"
    msg "echo \"\$script\" > \"$tmp_path\""
    echo "$script" > "$tmp_path"
    cmd cp "$tmp_path" "$INSTALL_PATH"
    cmd chmod +x "$INSTALL_PATH"
    cmd rm "$tmp_path"

    # Copy systemd units.
    local from="$(get-data backup-btrfs -path)"
    cmd cp "$from/backup-btrfs.service" "$SYSTEMD_INSTALL_DIR"
    cmd cp "$from/backup-btrfs.timer" "$SYSTEMD_INSTALL_DIR"

    # Enable and start systemd service+timer pair.
    ## Don't enable backup-btrfs.service directly; the timer does it.
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
    cmd rm "$SYSTEMD_INSTALL_DIR/backup-btrfs.timer"
    cmd rm "$SYSTEMD_INSTALL_DIR/backup-btrfs.service"

    # Remove from $install_path.
    cmd rm "$INSTALL_PATH"

    # Tell user it's been removed.
    msg "Uninstall complete."
}

USAGE="Usage: backup-btrfs [DEBUG] {action}

Run btrfs backups. Here are the valid actions.

backup     Run btrfs backups according to config.
install    Bundle script and config into no-arg system script and set
           systemd to automatically run it every hour or so.
reinstall  Redo install with latest script and config versions.
uninstall  Remove installed file and systemd units.
usage      Show this usage information.

If 'DEBUG' is passed, then actions are simulated instead. This is good
for testing purposes, such as if the control script has just been
modified.
"
## Usage: usage
# Show usage message.
usage() {
    msg "$USAGE"
}

## Usage: main "$@"
# Run the script.
main() {
    if [ "$1" = "DEBUG" ]; then
        DEBUG=true
        shift
    fi
    if [ $# != '1' ]; then
        usage
        fatal "Expected exectly 1 action."
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
