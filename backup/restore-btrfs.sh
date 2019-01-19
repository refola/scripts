#!/usr/bin/env bash
##
# restore-btrfs.sh
##
# Companion script to backup-btrfs.sh, to aid restorations.
##
# TODO: I should either make the configurations declarative enough
# that this can use the same config files as the backup script, or
# just switch to something listed at
# https://btrfs.wiki.kernel.org/index.php/Incremental_Backup .
##
# NOTE: This is very kludgy compared to the backup script. Please make
# sure to backup your backups before using them with this. The main
# convenience is being able to clone the latest subvolume from the
# appropriate place in one snapshot root folder and copy the latest to
# another.
##
# TODO: Deduplicate copied code in common with backup-btrfs.sh,
# without making this depend on more than basic GNU utilities, Bash,
# and btrfs-progs.
##

### overall data flow ###
## Backup structure:
# /path/to/backup/@subvol1/date1
# /path/to/backup/@subvol1/[...]
# /path/to/backup/@subvol1/dateN
# /path/to/backup/@[...]
# /path/to/backup/@subvolK/date1
# /path/to/backup/@subvolK/[...]
# /path/to/backup/@subvolK/dateN
## Desired restore structure:
# /path/to/restore/@subvol1/dateN
# /path/to/restore/@[...]
# /path/to/restore/@subvolK/dateN


### global variable declarations ###

# Set by main()
DEBUG= # Disabled (non-blank for enabled)

# Set near run-exit-traps()
EXIT_TRAPS=

# Set near usage()
USAGE=

# Set by restore()
LOG_FILE= # TODO: Need cleaner log init code location

# Set by restore()
FROM=
TO=


### generic utility functions ###

# list of commands to run on exit
EXIT_TRAPS=()
## Usage: trap run-exit-traps EXIT
# Run everything in ${exit_traps[@]}.
run-exit-traps() {
    local i
    for i in "${EXIT_TRAPS[@]}"; do
        msg "running exit trap: $i"
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


### (restore) logging and log checking ###

## Usage: log info
# Timestamps info and appends it to $LOG_FILE.
log() {
    local stamp data="$*"
    cmd-eval sync
    stamp="$(date --utc --iso-8601=seconds)"
    cmd-eval "echo '$stamp: $data' | sudo tee --append '$LOG_FILE' >/dev/null"
}

## Usage: log-* subvol/snapshot
# Logs the * of cloning subvol/snapshot.
log-start()    { log    "Start clone: '$1'"; }
log-complete() { log "Complete clone: '$1'"; }
log-remove()   { log   "Remove clone: '$1'"; }

## Usage: last-log-for subvol/snapshot
# Echoes the last log entry for subvol/snapshot.
last-log-for() { grep "$1" "$LOG_FILE" | tail -n1; }
## Usage: last-log-matches subvol/snapshot patten
# Checks if the last log entry for subvol/snapshot matches pattern.
last-log-matches() { last-log-for "$1" | grep --quiet "$2"; }

## Usage: last-action-is-* subvol/snapshot
# Checks if the last logged action for subvol/snapshot is *
last-log-is-start()  { last-log-matches "$1"     "Start"; }
last-log-is-start()  { last-log-matches "$1"  "Complete"; }
last-log-is-remove() { last-log-matches "$1"    "Remove"; }
last-log-is-null()   { ! grep --quiet   "$1" "$LOG_FILE"; }


### btrfs utility functions ###

## Usage: name="$(last-backup snap-dir [...])"
# Get name of last backup in each given backup directory, or empty
# string if there is no backup in common.
##
# NOTE: This assumes that this script and backup-btrfs.sh are the only
# sources of items in the snapshot directory.
last-backup() {
    local last IFS=$'\n'
    # Go thru all snapshots in first directory, in reverse order.
    for snap in $(find "$1" -maxdepth 1 -mindepth 1 | sort -r); do
        # Get just the snapshot's name without containing directory.
        snap="${snap/*\//}"
        for dir in "$@"; do
            if ! [ -d "$dir/$snap" ]; then
                # Give up on backup name at first failure.
                continue 2
            fi
        done
        # Since snapshots are listed in reverse (newest-first) order,
        # the first success is correct.
        last="$snap"
        break
    done
    echo "$last" # Show result, if any.
}


### initial checks and setup ###

## Usage: init
# Runs initialization for the script. This should be called by main()
# and only main(), once and only once.
init() {
    local deps lockdir
    deps=(btrfs date dirname find mkdir rmdir sleep sudo sync tee)
    # Warn about debug mode if active
    if [ -n "$DEBUG" ]; then
        msg "Debug mode active. Essential commands will not be ran."
    fi

    # Check that required programs are installed.
    if ! type -P "${deps[@]}" > /dev/null; then
        fatal "Cannot find all required commands."
    fi

    # Check lock directory to prevent interference.
    lockdir="/tmp/.backup-btrfs.lock"
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
}


### main stuff ###

## Usage: maybe-restore-sv subvol
# Checks if it's okay to restore a snapshot of the given subvolume in
# the given restore directory. This is true iff the subvolume
# directory to restore to is empty.
maybe-restore-sv() {
    local sv="$1" source="$FROM/$sv" dest="$TO/$sv" last sv_snap
    last="$(last-backup "$source")"
    sv_snap="$sv/$last"
    if last-log-is-remove "$sv_snap" || last-log-is-null "$sv_snap"; then
        [ ! -e "$dest" ] && cmd mkdir "$dest"
        log-start "$sv_snap"
        cmd-eval "sudo btrfs send '$source/$last' | sudo btrfs receive '$dest'" ||
            fatal "Failed to clone '$source/$last' to '$dest'."
        log-complete "$sv_snap"
    fi
}

## Usage: maybe-remove-sv subvol
# Removes all snapshots of given subvolume in the restore directory
# iff the log indicates an incomplete transfer.
maybe-remove-sv() {
    local sv="$1" dest="$TO/$sv" last_from last_to sv_snap
    last_from="$(last-backup "$FROM/$sv")"
    last_to="$(last-backup "$dest")"
    sv_snap="$sv/$last_to"
    # Make sure snapshots haven't changed since possible interrupted run.
    [ "${last_from-$last_to}x" = "${last_to-$last_from}x" ] &&
        fatal "Last snapshot disagreement: '$FROM/$sv/$last_from' vs '$dest/$last_to'."
    # Check if it's okay to delete and delete it if so.
    [ -e "$dest/$last_to" ] && # it exists
        [ "$last_from" = "$last_to" ] && # it's of the latest source
        last-action-is-start "$sv_snap" && # it's incomplete
        cmd sudo btrfs subvolume delete "$dest/$last" && # remove it
        log-remove "$sv_snap" # log removal
}

## Usage: restore from to
# Restore (clone) latest subvolumes from 'from' to 'to'.
restore() {
    local subvol sv

    # Check if locations might be valid
    [ -d "$FROM" ] || fatal "Can't find backups at '$FROM'."
    [ -d "$TO" ] ||
        ([ -d "$(dirname "$TO")" ] && cmd mkdir "$TO") ||
        fatal "Can't find restore destination at '$TO'" \
              "or can't create it in parent directory."
    cmd touch "$LOG_FILE" # Only log after directory checks

    # Loop thru subvolumes
    cd "$FROM" || fatal "Can't 'cd' to '$FROM'"
    for subvol in */; do
        sv="${subvol/%'/'}" # trim trailing '/'
        maybe-remove-sv "$sv"
        maybe-restore-sv "$sv"
    done
}

USAGE="Usage: restore-btrfs [DEBUG] from-path to-path

Restore (clone) latest snapshot of each subvolume from 'from-path' to
'to-path'.

If 'DEBUG' is passed, then actions are simulated instead. This is good
for testing purposes, as a dry run."
## Usage: usage
# Show usage message.
usage() { msg "$USAGE"; }

## Usage: main "$@"
# Run the script.
main() {
    if [ "$1" = "DEBUG" ]; then
        DEBUG=true
        shift
    fi
    if [ $# != '2' ]; then
        usage
        fatal "Need two paths."
    fi

    FROM="$1" TO="$2"
    LOG_FILE="$TO/restore.log"
    init
    restore
}

main "$@"
