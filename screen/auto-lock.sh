#!/usr/bin/env bash
## auto-lock.sh
# Automatically lock the screen within a specific time range.

# times for comparison, in seconds since the epoch; set by get-times()
START=
END=
NOW=

SCRIPT_NAME="auto-lock"
USAGE="$SCRIPT_NAME [configure | help | install | maybe-lock | uninstall]

When ran without options, show this help info and exit.

Options are as follows:

configure    Show format information and edit the configuration file.
help         Show this usage info and exit.
install      Set a user systemd unit file to run this automatically.
maybe-lock   Lock if and only if within configured time range.
uninstall    Remove the user systemd unit file.
"


### UTILITY FUNCTIONS

## fail [error ...]
# Show error and exit.
fail() {
    echo "Fatal: $*" >&2
    exit 1
}

## my_var="$(get-cfg cfg_name cfg_desc)"
# Get configuration from cfg_name, showing cfg_desc and prompting the
# user to edit it as needed.
get-cfg() {
    local cfg_name="$2" cfg_desc="$3"
    local result
    result="$(get-config "$SCRIPT_NAME/$cfg_name" -what-do "$cfg_desc")"
    if [ $? != "0" ]; then
        fail "get-cfg(): Could not get config $cfg_name."
    else
        echo "$result"
    fi
}

# Lock the screen.
lock() {
    qdbus org.freedesktop.ScreenSaver /ScreenSaver Lock
}

# Read the configs and current time, setting $START, $END and $NOW
# accordingly, in seconds since the epoch.
get-times() {
    START="$(date +%s --date="$(get-cfg start "The lockout start time in 24-hour 'HH:MM' format")")"
    END="$(date +%s --date="$(get-cfg end "The lockout end time in 24-hour 'HH:MM' format")")"
    NOW="$(date +%s)" || fail "get-times(): Could not get current time"
}

## rm-cfgs cfg_name [...]
# Remove given configs.
rm-cfgs() {
    for cfg in "$@"; do
        rm "$(get-config -path "$SCRIPT_NAME/$cfg")"
    done
}

# Return status code indicating if we're in the lock time range.
should-lock-now() {
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
    read-configs
}

# Show usage info.
help() {
    echo "$USAGE"
}

# Install user systemd unit file.
install() {
    fail "install(): unimplemented"
}

# Lock iff it's the right time.
maybe-lock() {
    if should-lock-now; then
        lock
    fi
}

# Uninstall user systemd unit file.
uninstall() {
    fail "uninstall(): unimplemented"
}


### MAIN ###

## main "$@"
# Go from args to actions.
main() {
    if [ $# -eq 0 ]; then
        help
    elif [ $# -eq 1 ]; then
        case "$1" in
            configure|help|install|maybe-lock|uninstall)
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
