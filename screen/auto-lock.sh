#!/usr/bin/env bash
## auto-lock.sh
# Automatically lock the screen within a specific time range.

# times for comparison, in seconds since the epoch; set by get-times()
START=
END=
NOW=

SCRIPT_NAME="auto-lock"
USAGE="$SCRIPT_NAME [command [args]]

Automatically lock the screen during a configured time.

When ran without options, show this help info and exit.

Commands are as follows:

configure         Show format information and edit the configuration file.
help              Show this usage info and exit.
install           Set a user systemd unit file to run this automatically.
is-active [-q]    Check if installed service is active.
is-installed [-q] Check if locking service is installed.
is-locked [-q]    Check if screen is already locked.
is-lock-time [-q] Check if it's time to be locked.
maybe-lock        Lock if and only if within configured time range.
pause [time]      Pause locking service, optionally resuming after given time.
reinstall         Uninstall and install.
resume            Resume automatic locking.
status [-q]       Check all the is-* statuses, suppressing output with -q.
uninstall         Remove the user systemd unit file.

Exit status:

All commands return 0 (true) if \"successful\" (i.e., either the
requested action was performed correctly or requested status is
true). Specific error/false returns are as follows, with values adding
if multiple conditions exist simultaneously.

maybe-lock  1 if already locked, 2 if not locking time.
status      1 if inactive, 2 if uninstalled, 4 if unlocked, 8 if not lock time.
"



### UTILITY FUNCTIONS

## fail [error ...]
# Show error and exit.
fail() {
    echo "Fatal: $*" >&2
    exit 1
}

## get-cfg var_name cfg_name cfg_desc
# Get configuration from cfg_name, showing cfg_desc and prompting the
# user to edit it as needed. On success, saves result to a global
# variable called var_name. On failure, exits the script with an
# error.
get-cfg() {
    local var_name="$1" cfg_name="$2" cfg_desc="$3"
    local result
    result="$(get-config "$SCRIPT_NAME/$cfg_name" -what-do "$cfg_desc")"
    if [ $? != "0" ]; then
        fail "get-cfg(): Could not get config $cfg_name."
    else
        eval "$var_name='$result'"
    fi
}

# Read the configs and current time, setting $START, $END and $NOW
# accordingly, in seconds since the epoch.
get-times() {
    get-cfg START start "The lockout start time in 24-hour 'HH:MM' format"
    START="$(date +%s --date="$START")"
    get-cfg END end "The lockout end time in 24-hour 'HH:MM' format"
    END="$(date +%s --date="$END")"
    NOW="$(date +%s)" || fail "get-times(): Could not get current time"
}

# Lock the screen.
lock() {
    qdbus org.freedesktop.ScreenSaver /ScreenSaver Lock
}

## q-code text code [-q]
# Echo text if and only if '-q' is not passed. Then return with status
# given by code.
q-code() {
    [ "$3" != '-q' ] &&
        echo "$1"
    return "$2"
}

## qdbus [args ...]
# Wrap qdbus or qdbus-qt5 command as appropriate.
qdbus() {
    local cmd
    for cmd in qdbus qdbus-qt5; do
        if which "$cmd" &>/dev/null; then
            command "$cmd" "$@"
            return
        fi
    done
    fail "qdbus(): Could not find real 'qdbus' command."
}

## rm-cfgs cfg_name [...]
# Remove given configs.
rm-cfgs() {
    for cfg in "$@"; do
        rm "$(get-config "$SCRIPT_NAME/$cfg" -path)"
    done
}

# Return status code indicating if we should lock the screen
should-lock-now() {
    ! is-locked -q &&   # shouldn't lock if it's already locked.
        is-lock-time -q
}

## x-in-xs x [xs ...]
# Check if the first given arg "x" is in the given list of "xs".
x-in-xs() {
    local x="$1"
    shift
    while [ $# -ge 1 ]; do
        if [ "$x" = "$1" ]; then
            return 0
        fi
        shift
    done
    return 1
}



### MAIN OPTION FUNCTIONS

# Guide user thru configuration.
configure() {
    rm-cfgs start end
    get-times
}

# Show usage info.
help() {
    echo "$USAGE"
}

# Install user systemd unit files.
install() {
    if is-installed -q; then
        echo "already installed"
        return 1
    fi
    get-times # make sure there's valid configuration first
    local prefix
    prefix="$(get-data "$SCRIPT_NAME/$SCRIPT_NAME" -path)" ||
        fail "install(): Could not get systemd unit file prefix"
    for ext in service timer; do
        systemctl --user --quiet enable "$prefix.$ext" ||
            fail "install(): Could not enable systemd unit '$prefix.$ext'"
    done
    systemctl --user --quiet start "$SCRIPT_NAME.timer" ||
        fail "install(): Could not start $SCRIPT_NAME.timer"
    echo "install finished"
}

# Tell if systemd timer is active.
is-active() {
    local code status
    systemctl --user --quiet is-active auto-lock.timer
    code=$?
    if [ $code = 0 ]; then
        status="auto-locking active"
    else
        status="auto-locking paused"
        code=1
    fi
    q-code "$status" "$code" "$1"
}
# Tell if systemd service and timer are installed.
is-installed() {
    local code status
    # TODO: streamline when/if systemd adds, e.g., 'is-existent'
    systemctl --user status auto-lock.service &>/dev/null
    code=$?
    # per 'man systemctl', exit status 4 is "no such unit". so instead
    # of checking for success (status code 0, "unit is active"; only
    # for brief instant that script is running from timer activating),
    # we check for lack of "no such unit" error.
    if [ $code != 4 ]; then
        status="auto-locker installed"
        code=0
    else
        status="auto-locker not installed"
        code=1
    fi
    q-code "$status" "$code" "$1"
}
# Tell if screen is already locked.
is-locked() {
    local code status
    [ "$(qdbus org.freedesktop.ScreenSaver /ScreenSaver GetActive)" = "true" ]
    code=$?
    if [ $code = 0 ]; then
        status=locked
    else
        status=unlocked
    fi
    q-code "$status" "$code" "$1"
}
# Tell if it's time to lock.
is-lock-time() {
    local code status
    get-times
    # problem: start and end wrap around. e.g., (start, now, end)
    # hours of (20, 22, 04) and (20, 03, 04) count as in the time
    # range. but (20, 05, 04) is not in the time range.
    ##
    # cases:
    ## 1: start < end:
    ### return true if start < now < end. otherwise false.
    ## 2: end < start:
    ### return false if end < now < start. otherwise true.
    ## 3: start == end:
    ### invalid times. fail.
    if [ "$START" -lt "$END" ]; then
        [ "$START" -lt "$NOW" ] && [ "$NOW" -lt "$END" ]
        code=$?
    elif [ "$END" -lt "$START" ]; then
        ! ([ "$END" -lt "$NOW" ] && [ "$NOW" -lt "$START" ])
        code=$?
    else
        fail "is-lock-time(): equal start and end times are invalid."
    fi
    if [ $code = 0 ]; then
        status="time to lock screen"
    else
        status="not time to lock screen"
    fi
    q-code "$status" "$code" "$1"
}

# Lock iff it's the right time.
maybe-lock() {
    should-lock-now &&
        lock
}

# Pause systemd timer.
pause() {
    if is-active -q; then
        systemctl --user stop auto-lock.timer
        if [ -n "$1" ]; then
            echo "Auto-locking will resume in $1."
            echo "Please manually run 'auto-lock resume' if command interrupted."
            sleep "$1"
            resume
        fi
    fi
}

# Uninstall and install systemd unit files.
reinstall() {
    uninstall
    install
}

# Resume systemd timer.
resume() {
    if ! is-active -q; then
        systemctl --user start auto-lock.timer
    fi
}

## status [-q]
# Check systemd service and locking status. Suppress output with -q.
# Exit status code is sum of whichever combination of these applies: 1
# if inactive, 2 if uninstalled, 4 if unlocked, 8 if not lock time.
status() {
    local status=0 pow=1
    for fn in is-active is-installed is-locked is-lock-time; do
        $fn "$@" || # "$@" passes '-q' if-and-only-if it was passed here
            ((status |= pow)) # "|=" is like "+=" for binary OR
                              # (equivalent in this case, but the less
                              # common operator more clearly expresses
                              # semantic intent of error code
                              # composition)
        ((pow*=2))
    done
    return $status
}

# Uninstall user systemd unit files.
uninstall() {
    if ! is-installed -q; then
        echo "already not installed"
        return 1
    fi
    for ext in service timer; do
        systemctl --user --quiet disable "$SCRIPT_NAME.$ext" ||
            fail "uninstall(): could not disable '$SCRIPT_NAME.$ext'"
    done
    echo "uninstall finished"
}



### MAIN ###

## main "$@"
# Go from args to actions.
main() {
    local -a arg_cmds=(is-active is-installed is-locked is-lock-time
                       pause status)
    local -a all_cmds=("${arg_cmds[@]}" configure help install maybe-lock
                      reinstall resume uninstall)
    case $# in
    0)
        help
        ;;
    1)
        if x-in-xs "$1" "${all_cmds[@]}"; then
            "$1"
        else
            fail "Invalid command '$1'"
        fi
        ;;
    2)
        if x-in-xs "$1" "${arg_cmds[@]}"; then
            "$@"
        else
            fail "Bad command '$1' or it doesn't accept arguments."
        fi
        ;;
    *)
        fail "Too many arguments."
        ;;
    esac
}

main "$@"
