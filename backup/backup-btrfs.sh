#!/usr/bin/env bash

DEPRECATION_NOTE="This script is deprecated. It has grown well beyond
the point where dealing with shell language quirks takes more time
than is saved by easier access to running programs and redirecting
their I/O. When I have the time, I plan to officially replace this
script with a more coherent and feature-rich 500±200 line Python, Go,
Lisp, or even C# program, quite possibly one already written by
someone else."

echo
echo -e "\e[31mWarning:\e[0;1m $DEPRECATION_NOTE\e[0m" >&2
echo

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
### presence in list checking
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

# Set by main(): must have usable defaults or installed version breaks
DEBUG= # Disabled (non-blank for enabled, or run with DEBUG)
## How much info should be shown
# -2: `fatal`
# -1: `fatal`, `msg`
#  0: `fatal`, `msg`, `cmd` goals
# +1: `fatal`, `msg`, `cmd` goals, `cmd` commands
# +2: `fatal`, `msg`, `cmd` goals, `cmd` commands, `cmd` outputs
# +3: `fatal`, `msg`, `cmd` goals, `cmd` commands, `cmd` outputs, `dbg`
VERBOSITY=0 # default

# Set near run-exit-traps()
EXIT_TRAPS=()

# Set by init()
DEPS=()
LOCKDIR=
TIMESTAMP= # invocation time, used as "latest snapshot time"

# Set near check-config()
CONFIG_USE=

# Set near install()
INSTALL_PATH=
SYSTEMD_TARGET=
AUTOGEN_MSG=

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
##
# Note: Each argument must be a complete eval-able string, so commands
# with quoted arguments should be given like "command 'quoted arg'".
add-exit-trap() {
    EXIT_TRAPS+=("$@")
}

## Usage: fatal "message about fatal error"
# Formats the given error message, outputs it to stderr, and exits the
# script.
##
# VERBOSITY: any
fatal() {
    echo -e "\e[31mError:\e[0;1m $*\e[0m" >&2
    exit 1
}

## Usage: msg "text to display"
# Outputs a message with a bit of formatting. This should be used
# instead of echo almost everywhere in this script.
##
# VERBOSITY: -1
msg() {
    [ "$VERBOSITY" -lt "-1" ] || echo -e "\e[1m$*\e[0m"
}

## Usage: cmd goal command [args ...]
# Normal function: Displays goal and runs given command (with given
# args as applicable). Exits script on error.
##
# In debug mode: Displays goal and shows command that would have been
# attempted.
##
# Note: Every simple system-changing command in this script should be
# ran via cmd. Use 'cmd-eval' if you need shell features like unix
# pipes.
##
# TODO: This should be merged with cmd-eval, but that seems to require
# a sophisticated string-escaping function to convert this one's
# variadicness into an eval'able string.
##
# VERBOSITY: 0 (goals), 1 (commands), 2 (outputs)
cmd() {
    [ "$VERBOSITY" -ge 0 ] && msg "Doing task: $1."
    [ "$VERBOSITY" -ge 1 ] && msg "\e[33msudo ${*:2}"
    if [ -z "$DEBUG" ]; then
        if [ "$VERBOSITY" -ge 2 ]; then
            sudo "${@:2}"
        else
            sudo "${@:2}" >/dev/null
        fi || fatal "Could not $1."
    fi
}

## Usage: cmd-eval goal "string to evaluate"
# Normal function: Displays goal and evals given string. Exits script
# on error.
##
# In debug mode: Displays goald and shows code that would have been
# eval'd.
##
# This is the less-automatic variant of 'cmd', intended for cases
# where things like unix pipes are required.
##
# NOTE: You need to manually add "sudo" to commands ran with
# this. Thus this is also good for non-root commands.
##
# VERBOSITY: 0 (goals), 1 (commands), 2 (outputs)
cmd-eval() {
    [ "$VERBOSITY" -ge 0 ] && msg "Doing task: $1."
    [ "$VERBOSITY" -ge 1 ] && msg "\e[33m${*:2}"
    if [ -z "$DEBUG" ]; then
        if [ "$VERBOSITY" -ge 2 ]; then
            eval "${*:2}"
        else
            eval "${*:2}" >/dev/null
        fi || fatal "Could not $1."
    fi
}

## Usage: dbg messages [...]
# Outputs a message with a bit of formatting. This should be used
# instead of echo for showing internal state for debugging.
##
# VERBOSITY: 3
dbg() {
    [ "$VERBOSITY" -lt 3 ] || echo -e "\e[33m$*\e[0m"
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

## Usage: list separator last_separator thing [...]
# Lists all the things, separating them with the given separator,
# switching to last_separator for separating the last two things.
## Example:
# my_list="$(list ',' ', and' a b c)"
# echo "$my_list" # a, b, and c
list() {
    local sep="$1" last="$2" out
    shift 2
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

## Usage: first-in-rest first rest [...]
# Checks if the first argument is the same as one of the rest.
first-in-rest() {
    local x
    for x in "${@:2}"; do
        [ "$1" = "$x" ] && return 0
    done
    return 1
}


### btrfs utility functions ###

## Usage: last_backup_name="$(last-backup "$(backup-dirs[@]}")"
# Get name of last backup found in all given backup directories, or
# empty string if they have no backup in common.
##
# NOTE: This assumes that this script is the only source of items in
# the snapshot directory.
last-backup() {
    local last IFS snap
    last= # Default to empty string.
    IFS=$'\n' # Split `find`'s results on newlines.

    # Go thru all snapshots in first directory, in reverse order
    # (newest first).
    for snap in $(find "$1" -maxdepth 1 -mindepth 1 | sort -r); do
        # Get just the snapshot's name without containing directory.
        snap="${snap/*\//}"
        for dir in "$@"; do
            if ! [ -d "$dir/$snap" ]; then
                # Give up on current backup name at first failure.
                continue 2
            fi
        done
        # The first (newest) success is correct.
        last="$snap"
        break
    done

    # Show result, if any.
    echo "$last"
}

## Usage: sanitized="$(sanitize subvol)"
# Sanitize given subvolume name by turning each '/' into a '-'.
##
# BUG: This doesn't distinguish between, e.g., "my-subvol" and
# "my/subvol".
sanitize() {
    echo "${1//\//-}"
}

### btrfs actions ###

## Usage: snapshot from-root to-snapshot-dir subvol
# Snapshots from-root/subvol to to-snapshot-dir/subvol/$TIMESTAMP
# (sanitizing subvol and making the directory for the to-snapshot-dir
# side, as applicable) and runs 'sync' to workaround a bug in btrfs.
snapshot() {
    local from_root="$1" to_snap_dir="$2" subvol="$3"
    local sanSv target from to
    sanSv="$(sanitize "$subvol")" || fatal "WTF? (sanitize $subvol)"
    target="$to_snap_dir/$sanSv"
    from="$from_root/$subvol"
    to="$target/$TIMESTAMP"
    exists "$target" ||  # Make sure target directory exists.
        cmd "make snap target directory '$target'" \
            mkdir -p "$target"
    cmd "snapshot '$from' to '$to'" \
        btrfs subvolume snapshot -r "$from" "$to"
    # TODO: Remove 'sync' when cloning stops requiring it after
    # snapshots. See
    # https://btrfs.wiki.kernel.org/index.php/Incremental_Backup#Initial_Bootstrapping
    cmd-eval "'sync' so 'btrfs send' works later" sync
}

## Usage: clone-or-update from to subvolume
# Use btrfs commands to make it so that to/sanitized-subvolume
# contains a copy of the latest btrfs subvolume at
# from/sanitized-subvolume.
##
# Result: to/sanitized-subvolume/latest-snapshot-date matches
# from/sanitized-subvolume/latest-snapshot-date.
clone-or-update() {
    local from="$1" to="$2" subvol="$3"
    local sv last parent
    sv="$(sanitize "$subvol")" || fatal "WTF? (sanitize $subvol)"
    last="$(last-backup "$from/$sv")"
    ([ "$?" = "0" ] && [ -n "$last" ]) ||
        fatal "Could not get last backup in '$from/$sv'."
    exists "$to/$sv" || # Make sure target directory exists.
        cmd "make clone target directory '$to/$sv'" \
            mkdir -p "$to/$sv"
    parent="$(last-backup "$to/$sv" "$from/$sv")"
    dbg "clone-or-update: from='$from' to='$to' subvol='$subvol'"
    dbg "                 sv='$sv' last='$last' parent='$parent'"

    if [ -z "$parent" ]; then # No subvols found, so bootstrap.
        cmd-eval "clone snapshot '$sv/$last' from '$from' to '$to'" \
                 "sudo btrfs send --quiet '$from/$sv/$last' | sudo btrfs receive '$to/$sv'"
    elif [ -e "$to/$sv/$last" ]; then # Nothing to do.
        msg "Skipping '$subvol' because '$to' already has the latest snapshot '$sv/$last' from '$from'."
    else # Incremental backup.
        cmd-eval "clone snapshot '$sv/$last' from '$from' to '$to' via parent '$sv/$parent'" \
                 "sudo btrfs send --quiet -p '$from/$sv/$parent' '$from/$sv/$last' | sudo btrfs receive '$to/$sv'"
    fi
}

## Usage: del-older-than location time min_keep_count subvolume
# Deletes btrfs snapshots for 'subvolume' at 'location' that are older
# than 'time', keeping at least the latest 'min_keep_count' regardless
# of age. Age is determined by the name of the snapshot, expected to
# be in ISO-8601 format and UTC, as used by the rest of this
# script. This is useful for deleting old snapshot archives to free up
# space.
##
# ASSUMPTION: Glob order is lexicographical.
delete-older-than() {
    local loc="$1" t="$2" keep="$3" sv="$4"
    local location stamp targets target i
    location="$loc/$(sanitize "$sv")" || fatal "WTF? (sanitize $sv)"
    stamp="$(date --utc --iso-8601=seconds --date="$t")"
    targets=("$location"/*)
    i=0
    while [[ $((i+keep)) -lt "${#targets[@]}" ]]; do
        target="${targets[$i]}"
        # "<" works because ISO-8601 makes chronological and
        # lexicographical sorting identical.
        if [[ "$target" < "$location/$stamp" ]]; then
            cmd "delete old subvolume '$target'" \
                btrfs subvolume delete "$target"
        else
            break
        fi
        ((i++)); true # "true" avoids ++'s surprising error semantic
    done
}


### high-level snapshot actions ###

## Usage: subvol-loop function num-fn-args fn-args [...] subvolumes [...]
# Iterates through each subvolume, running the given 'function' with
# its 'fn-args', of which there are 'num-fn-args', appending the
# current subvolume to the end of the arguments for 'function'.
subvol-loop() {
    local fn num_fn_args fn_args subvols args svs sv
    fn="$1" num_fn_args="$2" # known-location args
    fn_args=("${@:3:$num_fn_args}") # known-but-variable-count args
    shift $((2+num_fn_args)) # shift to subvolume list
    subvols=("$@") # unknown variable length

    # Inform user of what's going on.
    args="'$(list "', '" "', and '" "${fn_args[@]}")'" ||
        fatal "WTF? (list ... fn_args)"
    svs="'$(list "', '" "', and '" "${subvols[@]}")'" ||
        fatal "WTF? (list ... fn_args)"
    msg "\e[32mRunning '$fn' with args ($args) on subvols ($svs)."

    # Actually run the function for the subvolumes.
    for sv in "${subvols[@]}"; do
        # Do the applicable action.
        $fn "${fn_args[@]}" "$sv" ||
            fatal "Could not run '$fn' with args $args on subvol '$sv'"
    done
}

## Usage: make-snaps from to subvolumes [...]
# Make a read-only btrfs snapshot at 'to' for each given subvolume in
# 'from'. This is directly useful for being able to revert file
# changes (which is _NOT_ a backup!), and the snapshots are useful for
# (incrementally) copying subvolumes to other devices for real
# backups.
make-snaps() {
    exists "$1" "$2" || return 1
    subvol-loop snapshot 2 "$@"
}

## Usage: copy-latest from to subvolumes [...]
# Copy the latest snapshot for each given subvolume in 'from' to
# 'to'. This is useful for real backups, (incrementally) copying
# entire subvolumes between devices.
copy-latest() {
    exists "$1" "$2" || return 1
    subvol-loop clone-or-update 2 "$@"
}

## Usage: delete-old snap_dir time subvolumes [...]
# DEPRECATED: Use delete-old-keep-n instead.
delete-old() {
    msg "Translating deprecated delete-old($(printf "'%s' " "$@")) to delete-old-keep-n($(printf "'%s' " "${@:1:2}" 1 "${@:3}"))."
    delete-old-keep-n "${@:1:2}" 1 "${@:3}"
}

## Usage: delete-old snap_dir time min_keep_count subvolumes [...]
# Delete snapshots older than 'time' from 'snap_dir', keeping at least
# the latest 'min_keep_count' snapshots regardless of age. 'time' is a
# date/time string as used by "date --date=STRING". For example, a
# time of "3 days ago" will delete snapshots which are more than 3
# days old. This is useful when the device for 'from' doesn't have
# much space and the device for 'to' acts as an archive of the old
# states of 'from'.
delete-old-keep-n() {
    exists "$1" || return 1
    subvol-loop delete-older-than 3 "$@"
    # Sync everything to free up cleared space.
    cmd "sync '$1' to free deleted snapshots' space" \
        btrfs filesystem sync "$1"
    # TODO: remove message when/if obsolete
    msg "Note that btrfs' cleanup of freed space may take a while longer."
}


### initial checks and setup ###

## Usage: init
# Runs initialization for the script. This should be called by main()
# and only main(), once and only once.
init() {
    # Notify of debug mode if active
    if [ -n "$DEBUG" ]; then
        msg "Debug mode active. External commands will not really be ran."
    fi
    # Also notify of VERBOSITY level if it's high enough
    dbg "VERBOSITY=$VERBOSITY"

    # Check that required programs are installed.
    DEPS=(btrfs cat chmod cp date find get-config get-data mkdir
          mktemp readlink rm rmdir sleep sudo sync systemctl)
    cmd-eval "make sure commands exist:\n\t${DEPS[*]}" \
             "type -P ${DEPS[*]} > /dev/null"

    # Check lock directory to prevent parallel runs.
    LOCKDIR="/tmp/.backup-btrfs.lock"
    cmd "acquire lock" mkdir "$LOCKDIR"
    # This is the only copy of the script running. Make sure we'll
    # clean up at the end.
    add-exit-trap "cmd 'remove lock directory' rmdir '$LOCKDIR'"

    # This loop repeatedly runs "sudo -v" to keep sudo from timing
    # out, enabling the script to continue as long as necessary,
    # without pausing for credentials.
    ##
    # Note: It's not necessary to explicitly activate sudo mode first,
    # since the lock acquisition already uses sudo.
    msg "Starting sudo-refreshing loop."
    ( while true; do
          cmd "wait just under a minute" sleep 50
          cmd-eval "refresh sudo timeout" "sudo -v"
      done; ) >/dev/null &
    add-exit-trap "kill $! # sudo-refreshing loop"

    # Get timestamp for new snapshots.
    TIMESTAMP="$(date --utc --iso-8601=seconds)" ||
        fatal "Could not get timestamp."
}


# Do not change the autogen stop line without also changing install()
# to match.
##### AUTOGEN STOP LINE #####

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
desired arguments. These functions work as follows:

make-snaps from to subvolumes ...

    Snapshot each listed subvolume under 'from', saving the snapshots
    under 'to'. Note that 'from' and 'to' must be under the same btrfs
    mount point, since snapshots merely copy references to the
    underlying data.

copy-latest from to subvolumes ...

    Copy the latest snapshot of each listed subvolume from 'from' to
    'to'. Note that this is only useful if 'from' and 'to' are on
    different partitions (and usually on different physical devices,
    like for backups), since otherwise lightweight snapshots could be
    used for the same effect without doubling disk usage.

delete-old location time subvolumes ...

    Delete all snapshots older than 'time' from listed subvolumes
    under 'location'. Note that 'time' is recommended to be relative
    like 'three weeks ago' and should probably be longer than the
    frequency that backups are done to the location.

To see an example for clarity, it is recommended to choose to edit the
default config. It is a reasonable starting template for basic backup
cases."

## Usage: check-config
# Checks that the config exists, exiting the script with a fatal error
# if not.
check-config() {
    # Check the config, explaining how it works if it isn't already set.
    get-config backup-btrfs/control_script -verbatim \
               -what-do "$CONFIG_USE" >/dev/null ||
        fatal "Could not get config."
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
SYSTEMD_TARGET="/etc/systemd/system"
# Yes, ShellCheck, I know where this string ends.
# shellcheck disable=SC1078,SC1079
AUTOGEN_MSG="## DO NOT EDIT THIS AUTOGENERATED FILE!
# This file was made via 'backup-btrfs install'. If you want to change
# it, then make the appropriate change in your own config (and/or
# the script itself) and run 'backup-btrfs reinstall'."$'\n'$'\n'$'\n'

## Usage: install
# Makes sure there's a valid config, copies this to $install_path, and
# sets a systemd service/timer pair to automatically run this every
# hour or so.
install() {
    local stop_at IFS location line script from
    msg "Installing script as system command."

    # Make sure the config exists.
    check-config

    # Read in every line of this script, stopping at the autogen stop
    # line that precedes the "### main stuff ###" section.
    stop_at="##### AUTOGEN STOP LINE #####"
    location="$(readlink -f "$0")" || # TODO: something less fragile than $0
        fatal "Could not get script location."
    while IFS= read -r line; do
        if [ "$line" = "$stop_at" ]; then
            break
        elif [ -z "$script" ]; then # leading shebang line
            script="$line"$'\n'"$AUTOGEN_MSG"
        else
            script="$script"$'\n'"$line"
        fi
    done < "$location"

    # Append function-wrapped config.
    script="$script"$'\n'"### config from install time, wrapped in function ###"
    script="$script"$'\n'"backup() {"
    script="$script"$'\n'"msg 'Running backups.'"
    script="$script"$'\n'"$(cat "$(get-config-path)")" ||
        fatal "Could not get config."
    script="$script"$'\n'"}"

    # Append init-running and backup-running.
    script="$script"$'\n'"init # Run init manually; this has no main."
    script="$script"$'\n'"backup # Run backup manually; this has no main."

    # Save to $install_path
    tmp_path="$(mktemp)" || fatal "Could not 'mktemp'."
    # Not expanding variables in this 'msg' line is intentional.
    # shellcheck disable=SC2016
    cmd-eval "save derived script to temp file" \
             'echo "$script" > "$tmp_path"'
    cmd "copy derived script from '$tmp_path'" \
        cp "$tmp_path" "$INSTALL_PATH"
    cmd "adjust permissions on '$INSTALL_PATH'" \
        chmod 0755 "$INSTALL_PATH" # rwxr-xr-x
    cmd "remove temp file '$tmp_path'" rm "$tmp_path"

    # Copy systemd units.
    from="$(get-data backup-btrfs -path)"
    cmd "copy systemd service" \
        cp "$from/backup-btrfs.service" "$SYSTEMD_TARGET"
    cmd "copy systemd timer" \
        cp "$from/backup-btrfs.timer" "$SYSTEMD_TARGET"

    # Enable and start systemd service+timer pair.
    ## Don't enable backup-btrfs.service directly; the timer does it.
    cmd "enable systemd timer" \
        systemctl --quiet enable backup-btrfs.timer
    cmd "start systemd timer" systemctl start backup-btrfs.timer

    # Tell user it's been installed.
    msg "Install complete! Here are the systemd timers to confirm."
    cmd-eval "list systemd timers" "systemctl list-timers"
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
    cmd "stop systemd timer" systemctl stop backup-btrfs.timer
    cmd "disable systemd timer" \
        systemctl --quiet disable backup-btrfs.timer
    cmd "disable systemd service" systemctl disable backup-btrfs.service

    # Remove systemd units.
    cmd "remove systemd timer" \
        rm "$SYSTEMD_TARGET/backup-btrfs.timer"
    cmd "remove systemd service" \
        rm "$SYSTEMD_TARGET/backup-btrfs.service"

    # Remove from $install_path.
    cmd "remove installed derived script" \
        rm "$INSTALL_PATH"

    # Tell user it's been removed.
    msg "Uninstall complete."
}

USAGE="Usage: backup-btrfs [options ...] {action} [options ...]

Run btrfs backups.


Actions:

backup     Run btrfs backups according to config.
install    Bundle script and config into no-arg system script and set
           systemd to automatically run it every hour or so.
reinstall  Redo install with latest script and config versions.
uninstall  Remove installed file and systemd units.
usage      Show this usage information.


Options:

DEBUG      Simulate actions and increase verbosity to maximum. This is
           good for testing purposes, such as after changing the
           control script.
quiet      Decrease verbosity by one level.
verbose    Increase verbosity by one level.


Note: Verbosity currently ranges from -2 to +3 and defaults to 0.
Note: Arguments may be abbreviated if unambiguous.
"
## Usage: usage
# Show usage message.
usage() {
    msg "$USAGE"
}

## Usage: main "$@"
# Run the script.
main() {
    local -a acts opts
    local action
    acts=(backup install reinstall uninstall usage)
    opts=(DEBUG quiet verbose)
    VERBOSITY=0
    while [ "$#" -ge "1" ]; do
        if first-in-rest "$1" "${acts[@]}"; then
            if [ -z "$action" ]; then
                action="$1"
            else
                fatal "Multiple actions given: $action, $1, [...]."
            fi
        elif first-in-rest "$1" "${opts[@]}"; then
            case "$1" in
                D*) DEBUG=true VERBOSITY=3 ;;
                v*)        ((VERBOSITY++)) ;;
                q*)        ((VERBOSITY--)) ;;
                *)   fatal "WTF? (opt $1)" ;;
            esac
        else
            fatal "Unknown argument '$1'."
        fi
        shift 1
    done
    case "$action" in
        b*|i*|r*|un*)     init; $action ;;
        us*)              usage; return ;;
        '')   usage; fatal "No action." ;;
        *) fatal "WTF? action=$action." ;;
    esac
}

main "$@"
