#!/usr/bin/env bash
##
# ram-monitor.sh
##
# Alert user to low memory situations while there's still time before
# the kernel's low memory killer activates.

# msg message
##
# Send the given message to $USER via the `write` command.
msg() { echo -e "$0: $1" | write "$USER"; }

# checkMemStats name stat1 stat2 minPercent [...]
##
# For stats in /proc/meminfo, check that stat1 is at least minPercent%
# of stat2 for at least one 4-tuple of (name, stat1, stat2,
# minPercent). If this fails for all 4-tuples, then output an error
# message informing the user of low memory and percentages free.
checkMemStats() {
    local name stat1 stat2 minPercent
    local percent pass="false" message="Low memory!"
    while [ "$#" -ge 4 ]; do
        name="$1"
        stat1="$(grep "$2" /proc/meminfo | egrep -o '[0-9]+')" ||
            msg "Could not get $2 value."
        stat2="$(grep "$3" /proc/meminfo | egrep -o '[0-9]+')" ||
            msg "Could not get $3 value."
        minPercent="$4"
        percent=$((stat1*100/stat2))
        [ "$percent" -ge "$minPercent" ] &&
            pass="true"
        message="$message"$'\n'"$name: ${percent}% free"
        shift 4
    done
    if [ "$pass" = "false" ]; then
        msg "$message"
        return 1
    fi
}

# main "$@"
##
# Run the script, with whichever parameters are available.
main() {
    local usage="$0 minRamPercent minSwapPercent

Constantly check RAM and swap levels, giving a warning if they both
get too low."

    if [ "$#" != 2 ]; then
        echo "$usage"
        exit 1
    fi
    mesg y # Enable `write` command
    while true; do
        checkMemStats RAM MemAvailable MemTotal "${1-20}" \
                      Swap SwapFree SwapTotal "${2-70}" ||
            sleep 9
        sleep 1
    done
}

main "$@"
