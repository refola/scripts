#!/bin/bash
##
# battery-logger.sh
##
# Log battery info.

## discharging
# Returns true iff the battery is discharging (unplugged).
discharging() {
    [ "$(get-stat status)" = Discharging ]
}

## get-stat file
# Echoes the given stat under `/sys/class/power_supply/BAT0`.
get-stat() {
    unmicro "$(cat "/sys/class/power_supply/BAT0/$1")"
}

## log [options] format [stuff to log]
# Logs stuff to $log_location. Accepts the same arguments as printf.
log() {
    # shellcheck disable=SC2059
    printf "$@" >> "$log_location"
}

## log-stat format file
# Logs the battery stat in the given file under
# `/sys/class/power_supply/BAT0`, formatting as indicated
log-stat() {
    log "$1" "$(get-stat "$2")"
}

## log-stats
# Log the following battery stats:
# - Current capacity as a percentage
# - Charge/max/design-max
# - Charge cycles
# - Charge rate
log-stats() {
    log "$(date -uIs)\n"
    local en ef efd
    en="$(get-stat energy_now)"
    ef="$(get-stat energy_full)"
    efd="$(get-stat energy_full_design)"
    log-stat 'Relative charge: %s%%\n' capacity
    log "Charge/Max/OriginalMax: ${en}Wh/${ef}Wh/${efd}Wh\n"
    log-stat 'Cycles: %s\n' cycle_count
    log-stat "Charge rate: $(discharging && echo -)%sW\n" power_now
    log '\n'
}

## unmicro number
# Divide a number by one million to convert from micro [unit] to
# [unit], but only if valid.
unmicro() {
    local dec # Decimal-containing converted number
    dec="$(echo "$1" | sed -r 's/([0-9]*)([0-9]{6})/\1.\2/g')"
    if [ "$dec" != "$1" ]; then
        # If conversion was successful, truncate trailing zeroes.
        echo "$dec" | sed -r 's/([0-9.]*[^0])0*/\1/g' |
            sed -r 's/\.$//g' # and trailing decimal if no digits after
    else
        # Otherwise, echo back the original number.
        echo "$1"
    fi
}

## main "$@"
# Run the script with all args.
usage="$0 [-q | --daemon [delay]]

Logs battery stats, optionally as a daemon, with a customizable delay
between runs. Pass '-q' to avoid this message in non-daemon mode.

Stats logged. Exiting."
main() {
    local log_location
    log_location="$(get-config "battery-logger/log-location" \
                    -what-do "where to save the log")" || exit 1

    # Make sure the log location exists.
    mkdir -p "$(dirname "$log_location")"
    touch "$log_location"

    if [ "$1" != "--daemon" ]; then
        [ "$1" != "-q" ] && echo "$usage"
        log-stats
        exit
    fi
    local delay="${2-60s}"
    while true; do
        log-stats
        sleep "$delay"
    done
}

main "$@"
