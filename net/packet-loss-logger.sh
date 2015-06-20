#!/bin/bash
## packet-loss-logger.sh
# Keep pinging a known reliable host and log a message each time a
# packet is lost.

usage="Usage: $(basename "$0") [quiet]

Repeatedly pings $host to check network connectivity, logging each
time there's a disruption.

If 'quiet' is passed, don't display anything; only log."

# Shortcut function for config-getting.
get() { get-config "packet-loss-logger/$1" -what-do "$2" || exit 1; }
host="$(get "host" "server to ping")"
delay="$(get "delay" "delay between pings (default seconds)")"
log_location="$(get "log-location" "where to save the log")"

# Default to verbose, unless set otherwise by main.
verbose="true"

# Prepends arguments with current date and time, then saves to log.
log() {
    local msg="$(date -Iseconds): $*"
    echo "$msg" >> "$log_location"
    if [ -n "$verbose" ]; then
        echo "$msg"
    fi
}

main() {
    # Unset verbosity if told to be quiet, otherwise echo usage.
    if [ "$1" = "quiet" ]; then
        verbose=""
    else
        echo "$usage" >&2
    fi

    # Make sure the log location exists.
    mkdir -p "$(dirname "$log_location")"
    touch "$log_location"

    # Record losses.
    count="0"
    lost="0"
    while true; do
        ((count++))
        sleep "$delay"
        if ! ping -c1 "$host" &>/dev/null && sleep "$delay"; then
            ((lost++))
            log "We've lost $lost/$count packets."
        fi
    done
}

main "$@"
