#!/bin/bash
## log-bandwidth.sh
# Save current bandwidth stats to a log.

log_location="$(get-config "log-bandwidth/log-location" \
                           -what-do "where to save the log")" || exit 1
IFS=$'\n'
interfaces=( $(get-config "log-bandwidth/interfaces" \
                          -what-do "list of network interfaces to log stats of") ) || exit 1

# Make sure the log location exists.
mkdir -p "$(dirname "$log_location")"
touch "$log_location"

## Usage: log [options] [stuff to log]
# Logs stuff to $log_location. Accepts the same arguments as echo.
log() {
    echo "$@" >> "$log_location"
}

## Usage: get-bytes interface direction
# Gets the number of bytes of bandwidth use for interface in
# direction, since "ip" doesn't have custom output format
# control. Direction can be RX or TX.
get-bytes() {
    local if="$1"
    local dir="$2"
    local result
    # Get stats
    result="$(ip -s link show "$if")"
    if [ "$?" = "0" ]; then
        # Find right line
        result="$(echo "$result" | grep -E -A1 "^ *$dir: bytes .*\$")"
        # Strip preceding wrong line
        result="$(echo "$result" | tail -n1)"
        # Get just the numbers
        result="$(echo "$result" | grep -E -o -m1 "[0-9]+")"
        # Limit to first match (byte count)
        result="$(echo "$result" | head -n1)"
        # Finally output result
        echo "$result"
        return 0
    else
        return 1
    fi
}

log "$(date -Iseconds)"
for interface in "${interfaces[@]}"; do
    for direction in RX TX; do
        bytes="$(get-bytes "$interface" "$direction")"
        if [ "$?" = "0" ]; then
            log -n "$interface $direction: "
            log "$bytes bytes"
        fi
    done
done
log # newline
