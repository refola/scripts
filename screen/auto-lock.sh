#!/usr/bin/env bash
## auto-lock.sh
# Automatically lock the screen within a specific time range.

NAME="auto-lock"
USAGE="$NAME [configure | help | install | maybe-lock | uninstall]

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

# Lock the screen.
lock() {
    qdbus org.freedesktop.ScreenSaver /ScreenSaver Lock
}

# Return status code indicating if we're in the lock time range.
should-lock-now() {
    fail "should-lock-now(): unimplemented"
}


### MAIN OPTION FUNCTIONS

# Guide user thru configuration.
configure() {
    fail "configure(): unimplemented"
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
        usage
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
