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
DEBUG= # Disabled (non-blank for enabled, or run with DEBUG)

# Set near run-exit-traps()
EXIT_TRAPS=

# Set by init()
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

## Usage: msg "text to display"
# Outputs a message with a bit of formatting. This should be used
# instead of echo almost everywhere in this script.
msg() {
    echo -e "\e[1m$*\e[0m"
}

## Usage: fatal "message about fatal error"
# Formats the given error message, outputs it to stderr, and exits the
# script.
fatal() {
    echo -e "\e[31mError:\e[0;1m $*\e[0m" >&2
    exit 1
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
cmd() {
    msg "Doing task: $1."
    if [ -n "$DEBUG" ]; then
        msg "\e[33msudo ${*:2}"
    else
        sudo "${@:2}" || fatal "Could not $1."
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
cmd-eval() {
    msg "Doing task: $1."
    if [ -n "$DEBUG" ]; then
        msg "\e[33m${*:2}"
    else
        eval "${*:2}" || fatal "Could not $1."
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
    # TODO: Remove 'sync' when obsolete. For now, it's necessary to
    # sync after snapshotting so that 'btrfs send' works
    # correctly. See:
    # https://btrfs.wiki.kernel.org/index.php/Incremental_Backup#Initial_Bootstrapping
    cmd-eval "'sync' so 'btrfs send' works later" sync
}

## Usage: clone-or-update from-dir to-dir subvolume
# Use btrfs commands to make it so that to-dir/sanitized-subvolume
# contains a copy of the latest btrfs subvolume at
# from-dir/sanitized-subvolume.
##
# Result: to-dir/sanitized-subvolume/latest-snapshot-date matches
# from-dir/sanitized-subvolume/latest-snapshot-date.
clone-or-update() {
    local from_dir="$1" to_dir="$2" subvol="$3"
    local sanSv last from last_parent
    sanSv="$(sanitize "$subvol")" || fatal "WTF? (sanitize $subvol)"
    from_dir="$from_dir/$sanSv"
    to_dir="$to_dir/$sanSv"
    last="$(last-backup "$from_dir")"
    ([ "$?" = "0" ] && [ -n "$last" ]) ||
        fatal "Could not get last backup in '$from_dir'."
    from="$from_dir/$last"
    exists "$to_dir" || # Make sure target directory exists.
        cmd "make clone target directory '$to_dir'" \
            mkdir -p "$to_dir"
    last_parent="$(last-backup "$to_dir" "$from_dir")"

    if [ -z "$last_parent" ]; then # No subvols found, so bootstrap.
        cmd-eval "clone snapshot '$from' to '$to_dir'" \
                 "sudo btrfs send '$from' | sudo btrfs receive '$to_dir'"
    elif [ -e "$to_dir/$last" ]; then # Nothing to do.
        msg "Skipping '$subvol' because '$to_dir' already has the latest snapshot from '$from_dir'."
    else # Incremental backup.
        cmd-eval "clone snapshot from '$from' to '$to_dir' via parent '$last_parent'" \
                 "sudo btrfs send -p '$from_dir/$last_parent' '$from' | sudo btrfs receive '$to_dir'"
    fi
}

## Usage: del-older-than location time subvolume
# Deletes each btrfs snapshot for subvolume at 'location' that is
# older than 'time', with age determined by the name of the snapshot,
# expected to be in ISO-8601 format and UTC, as used by the rest of
# this script. This is useful for deleting old snapshot archives to
# free up space.
delete-older-than() {
    local location stamp maybe_older
    location="$1/$(sanitize "$3")" || fatal "WTF? (sanitize $3)"
    stamp="$(date --utc --iso-8601=seconds --date="$2")"
    for maybe_older in "$location"/*; do
        # "<" works because ISO-8601 makes chronological and
        # lexicographical sorting identical.
        if [[ "$maybe_older" < "$location/$stamp" ]]; then
            cmd "delete old subvolume '$maybe_older'" \
                btrfs subvolume delete "$maybe_older"
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

## Usage: make-snaps from to subvolume [...]
# Make a read-only btrfs snapshot at 'to' for each given subvolume in
# 'from'. This is directly useful for being able to revert file
# changes (which is _NOT_ a backup!), and the snapshots are useful for
# (incrementally) copying subvolumes to other devices for real
# backups.
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
    local program
    # Notify of debug mode if active
    if [ -n "$DEBUG" ]; then
        msg "Debug mode active. External commands will not really be ran."
    fi

    # Check that required programs are installed.
    for program in btrfs date find get-config sleep sync; do
        cmd-eval "make sure '$program' command exists" \
                 "type -P $program > /dev/null"
    done

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
    local stop_at IFS line script from
    msg "Installing script as system command."

    # Make sure the config exists.
    check-config

    # Read in every line of this script, stopping at the autogen stop
    # line that precedes the "### main stuff ###" section.
    stop_at="##### AUTOGEN STOP LINE #####"
    while IFS= read -r line; do
        if [ "$line" = "$stop_at" ]; then
            break
        elif [ -z "$script" ]; then # leading shebang line
            script="$REPLY"$'\n'"$AUTOGEN_MSG"
        else
            script="$script"$'\n'"$line"
        fi
    done < "$(readlink -f "$0")" # TODO: something less fragile than $0

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
        chmod +x "$INSTALL_PATH" # TODO: change all perm bits
    cmd "remove temp file '$tmp_path'" rm "$tmp_path"

    # Copy systemd units.
    from="$(get-data backup-btrfs -path)"
    cmd "copy systemd service" \
        cp "$from/backup-btrfs.service" "$SYSTEMD_TARGET"
    cmd "copy systemd timer" \
        cp "$from/backup-btrfs.timer" "$SYSTEMD_TARGET"

    # Enable and start systemd service+timer pair.
    ## Don't enable backup-btrfs.service directly; the timer does it.
    cmd "enable systemd timer" systemctl enable backup-btrfs.timer
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
    cmd "disable systemd timer" systemctl disable backup-btrfs.timer
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
##
# TODO: restructure arg parsing to be "[options ...] action", and add
# "quiet" option(s) to suppress cmd[-eval] goal output (and msg).
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
