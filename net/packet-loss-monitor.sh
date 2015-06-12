#!/bin/bash
## packet-loss-monitor.sh
# Keep pinging a known reliable host and produce an audible warning
# each time a packet is lost.

max="5"
host="google.com"
delay="5"

usage="Usage: $(basename "$0") [max]

Repeatedly pings google.com to check network connectivity, warning in
multiple ways if there's a disruption. If max consecutive packets are
lost, say that we're giving up and stop the script.

Without max being passed, this script defaults to a limit of $max
consecutive lost packets."

msg() {
    say "$@"
    echo "$@" | wall
}

if [ -n "$1" ]
then
    max="$1"
else
    echo "$usage" >&2
fi

streak="0"
while true
do
    if ! ping -c1 "$host" &>/dev/null && sleep "$delay"
    then
        ((streak++))
        msg "We lost packet number $streak."
        if [ "$streak" = "$max" ]
        then
            msg "We lost $max packets in a row. We're giving up!"
            exit 1
        fi
    else
        streak="0"
    fi
done
