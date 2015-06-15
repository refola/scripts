#!/bin/bash
## packet-loss-logger.sh
# Keep pinging a known reliable host and log a message each time a
# packet is lost.

usage="Usage: $(basename "$0") [quiet]

Repeatedly pings $host to check network connectivity, logging each
time there's a disruption.

If 'quiet' is passed, don't display anything unneccessary; only log."

this="packet-loss-logger" # namespace for this script's configs
host="$(get-config "$this/host" -what-do "server to ping")" || exit 1
delay="$(get-config "$this/delay" \
                           -what-do "delay between pings (default seconds)")" || exit 1
log_location="$(get-config "$this/log-location" \
                           -what-do "where to save the log" \
                           -var-rep )" || exit 1

# Default to verbose, unless set otherwise by main.
verbose="true"

# Prepends arguments with current date and time, then saves to log.
log() {
    local msg="$(date "+%F_%H%M:%S UTC%:::z"): $*"
    echo "$msg" >> "$log_location"
    if [ -n "$verbose" ]
    then
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
    while true
    do
        ((count++))
        if ! ping -c1 "$host" &>/dev/null && sleep "$delay"
        then
            log "We lost packet number $count."
        fi
    done
}

main "$@"
