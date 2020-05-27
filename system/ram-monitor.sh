#!/usr/bin/env bash
##
# ram-monitor.sh
##
# Alert user to low memory situations while there's still time before
# the kernel's low memory killer activates.

# msg message
##
# Send the given message to $USER via the `write` command.
msg() {
    if which notify-send &>/dev/null; then
        # we can show fancy notifications
        notify-send -a "$0" "$0" "$1"
    else
        # fallback to standard *nix utilities
        mesg y # Enable `write` command
        echo -e "$0: $1" | write "$USER"
    fi
}

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

ram_default=20
swap_default=70
usage="$0 [-q | --quiet] [minRamPercent [minSwapPercent]]

Constantly check RAM and swap levels, giving a warning if they both
get too low. By default, require at least $ram_default% free RAM, or
at least $swap_default% free swap.

With '-q' or '--quiet', only show low memory and error messages."

# main "$@"
##
# Run the script, with whichever parameters are available.
main() {
    local quiet
    if [ "$1" = "-q" ] || [ "$1" = "--quiet" ]; then
        quiet=true
        shift
    fi
    if [ "$#" != 2 ] && [ -z "$quiet" ]; then
        echo "$usage"
    fi
    [ -z "$quiet" ] &&
        msg "$0 started. This is how low memory alerts will appear."
    while true; do
        checkMemStats RAM MemAvailable MemTotal "${1-$ram_default}" \
                      Swap SwapFree SwapTotal "${2-$swap_default}" ||
            sleep 9 # wait longer after reporting low memory to reduce spam
        sleep 1
    done
}

main "$@"
