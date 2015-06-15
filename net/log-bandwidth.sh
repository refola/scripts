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

date -Iseconds >> "$log_location"
for interface in "${interfaces[@]}"; do
    for direction in RX TX; do
        echo -n "$interface: $direction " >> "$log_location"
        ifconfig "$interface" | grep "$direction packets" | sed 's/ *[RT]X packets [0-9]* *//' >> "$log_location"
    done
done
echo >> "$log_location"
