#!/usr/bin/env bash
## auto-lock.sh
# Automatically lock the screen within a specific time range.

# times for comparison, in seconds since the epoch; set by get-times()
START=
END=
NOW=

SCRIPT_NAME="auto-lock"
USAGE="$SCRIPT_NAME [option]

Automatically lock the screen during a configured time.

When ran without options, show this help info and exit.

Options are as follows:

configure    Show format information and edit the configuration file.
help         Show this usage info and exit.
install      Set a user systemd unit file to run this automatically.
maybe-lock   Lock if and only if within configured time range.
reinstall    Uninstall and install.
uninstall    Remove the user systemd unit file.

Returns true (0) if the action was successful. Otherwise returns a
false value. In particular, maybe-lock returns true if it actually
caused the screen to become locked and false if the screen was already
locked or if it's not during the locking time.
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

# Lock the screen.
lock() {
    qdbus org.freedesktop.ScreenSaver /ScreenSaver Lock
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

## rm-cfgs cfg_name [...]
# Remove given configs.
rm-cfgs() {
    for cfg in "$@"; do
        rm "$(get-config "$SCRIPT_NAME/$cfg" -path)"
    done
}

# Return status code indicating if we're in the lock time range.
should-lock-now() {
    # First, don't lock if it's already locked.
    if [ "$(qdbus org.freedesktop.ScreenSaver /ScreenSaver GetActive)" = "true" ]; then
        false; return
    fi

    # Now check if it should be locked based on time.
    get-times
    # Problem: START and END wrap around. E.g., (START, NOW, END)
    # hours of (20, 22, 04) and (20, 03, 04) count as in the time
    # range. But (20, 05, 04) is not in the time range.
    ##
    # Cases:
    ## 1: START < END:
    ### Return true if START < NOW < END. Otherwise false.
    ## 2: END < START:
    ### Return false if END < NOW < START. Otherwise true.
    ## 3: START == END:
    ### Invalid times. Fail.
    if [ "$START" -lt "$END" ]; then
        if [ "$START" -lt "$NOW" ] && [ "$NOW" -lt "$END" ]; then
            true; return
        else
            false; return
        fi
    elif [ "$END" -lt "$START" ]; then
        if [ "$END" -lt "$NOW" ] && [ "$NOW" -lt "$START" ]; then
            false; return
        else
            true; return
        fi
    else
        fail "should-lock-now(): equal start and end times are invalid."
    fi
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
    get-times # make sure there's valid configuration first
    local prefix
    prefix="$(get-data "$SCRIPT_NAME/$SCRIPT_NAME" -path)" ||
        fail "install(): could not get systemd unit file prefix"
    for ext in service timer; do
        systemctl --user enable "$prefix.$ext" ||
            fail "install(): could not enable systemd unit '$prefix.$ext'"
    done
    systemctl --user start "$SCRIPT_NAME.timer" ||
        fail "install(): could not start $SCRIPT_NAME.timer"
}

# Lock iff it's the right time.
maybe-lock() {
    should-lock-now &&
        lock
}

# Uninstall and install systemd unit files.
reinstall() {
    uninstall &&
        install
}

# Uninstall user systemd unit files.
uninstall() {
    for ext in service timer; do
        systemctl --user disable "$SCRIPT_NAME.$ext" ||
            fail "uninstall(): could not disable '$SCRIPT_NAME.$ext'"
    done
}


### MAIN ###

## main "$@"
# Go from args to actions.
main() {
    if [ $# -eq 0 ]; then
        help
    elif [ $# -eq 1 ]; then
        case "$1" in
            configure|help|install|maybe-lock|reinstall|uninstall)
                "$1"
                ;;
            *)
                fail "Invalid arg"
                ;;
        esac
    else
        fail "Too many args"
    fi
}

main "$@"
