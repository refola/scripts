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

### TODO: error consideration ###
## Problem: interruption
# - Program can be interrupted mid-restore
# - Partially-cloned snapshots might be hard to identify
# - Don't want to waste time recloning good snapshots
## Fixes
# - Log transfer start/complete in well-defined format in destination
# - Make sure to sync before logging completion
# - Before each transfer, check log for started clone that didn't complete
# - If partial clone exists, quit after asking user to delete it and
#   restart script
# - If partial clone doesn't exist, proceed as if this is the first
#   time, but still logging action
## Problem: clobbering
# - Script can be pointed at an in-use location
# - Don't want to overwrite existing data
# - Don't want to add extra from-scratch clones where parents exist
## Fixes
# - Skip nonempty unlogged destination @subvol folders?

### global variable declarations ###

# Set by main()
DEBUG= # Disabled (non-blank for enabled)

# Set near run-exit-traps()
EXIT_TRAPS=

# Set near usage()
USAGE=

# Set by restore()
LOG_FILE= # TODO: Need cleaner log init code location


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


### (restore) logging and log checking ###


## Usage: log info
# Timestamps info and appends it to $LOG_FILE.
log() {
    local stamp data="$*"
    stamp="$(date --utc --iso-8601=seconds)"
    cmd-eval "echo '$stamp: $data' | sudo tee --append '$LOG_FILE' >/dev/null"
}

## Usage: log-clone-start subvol snapshot
# Logs the start of cloning subvol/snapshot.
log-clone-start() { log "Starting clone: '$1/$2'"; }

## Usage: log-clone-complete subvol snapshot
# Logs the completion of cloning subvol/snapshot.
log-clone-complete() { log "Completed clone: '$1/$2'"; }

## Usage: in-log info
# Checks if given 'info' is in the log.
in-log() { grep --quiet "$1" "$LOG_FILE"; }

## Usage: clone-start-logged subvol snapshot
# Checks if the log contains the start of cloning subvol/snapshot.
clone-start-logged() { in-log "Starting clone: '$1/$2'"; }
## Usage: clone-complete-logged subvol snapshot
# Checks if the log contains the completion of cloning
# subvol/snapshot.
clone-complete-logged() { in-log "Completed clone: '$1/$2'"; }


### btrfs utility functions ###

## Usage: last_backup_name="$(last-backup "$(backup-dirs[@]}")"
# Get name of last backup in each given backup directory, or empty
# string if there is no backup in all.
##
# NOTE: This assumes that this script is the only source of items in
# the snapshot directory.
last-backup() {
    # Default to empty string.
    local last=

    # We need to split `find`'s results on newlines.
    local old_IFS="$IFS"
    IFS=$'\n'
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

    # Restore old `$IFS`
    IFS="$old_IFS"
    # Show result, if any.
    echo "$last"
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
}


### main stuff ###

## Usage: okay-to-restore restore-dir subvol snapshot
# Checks if it's okay to restore to the given location.
## TODO:
# These conditions are too strict. Check other TODOs for details.
okay-to-restore() {
    local d="$1" sv="$2" snap="$3"
    exists "$d/$sv" && # destination exists
    ! exists "$d/$sv/$snap" && # snapshot doesn't exist
    ! clone-start-logged "$sv" "$snap" && # clone not attempted
    ! clone-complete-logged "$sv" "$snap" # clone not made
}

## Usage: restore from to
# Restore (clone) latest subvolumes from 'from' to 'to'.
restore() {
    local from="$1" to="$2"
    LOG_FILE="$to/restore.log"
    # Check if locations might be valid
    exists "$from" || fatal "Can't find backups at '$from'."
    exists "$to" ||
    (exists "$(dirname "$to")" && cmd mkdir "$to") ||
    fatal "Can't find restore destination at '$to'" \
          "or can't create it in parent directory."
    cmd touch "$LOG_FILE" # Only log after directory checks
    # TODO: handle error considerations listed in opening comments.

    # Loop thru subvolumes
    local sv source dest last
    cd "$from" || fatal "Can't 'cd' to '$from'"
    for subvol in */; do
    sv="${subvol/%'/'}" # trim trailing '/'
    source="$from/$sv"
    dest="$to/$sv"
    exists "$dest" || cmd mkdir "$dest" ||
        fatal "Can't find or create restore destination '$dest'."
    last="$(last-backup "$source")"
    if okay-to-restore "$to" "$sv" "$last"; then
        log-clone-start "$sv" "$last"
        cmd-eval "sudo btrfs send '$source/$last' | sudo btrfs receive '$dest'" ||
        fatal "Failed to clone '$source/$last' to '$dest'."
        log-clone-complete "$sv" "$last"
    else
        msg "Couldn't restore '$from/$sv/$last' to '$dest'."
    fi
    done
}

USAGE="Usage: restore-btrfs [DEBUG] from-path to-path

Restore (clone) latest snapshot of each subvolume from 'from-path' to
'to-path'.

If 'DEBUG' is passed, then actions are simulated instead. This is good
for testing purposes, as a dry run."
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
    if [ $# != '2' ]; then
        usage
        fatal "Need two paths."
    fi

    init
    restore "$1" "$2"
}

main "$@"
