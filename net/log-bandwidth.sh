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
    ip -s link show "$if" | \ # Get stats
        grep -E -A1 "^ *$dir: bytes .*\$" | \ # Find right line
        tail -n1 | \ # Strip preceding wrong line
        grep -E -o -m1 "[0-9]+" | \ # Get just the nmubers
        head -n1 # Limit to first match (byte count)
}

log "$(date -Iseconds)"
for interface in "${interfaces[@]}"; do
    for direction in RX TX; do
        log -n "$interface $direction: "
        log "$(get-bytes "$interface" "$direction") bytes"
    done
done
log # newline
