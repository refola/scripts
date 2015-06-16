#!/bin/bash
## packet-loss-alerter.sh
# Keep pinging a known reliable host, produce an audible warning each
# time a packet is lost, and produce a more annoying warning and exit
# when the maximum number of consecutive lost packets is reached.

# Shortcut function for config-getting.
get() { get-config "packet-loss-alerter/$1" -what-do "$2" || exit 1; }
max="$(get "max-lost" "number of packets lost in a row before giving up (0 = never give up)")"
host="$(get "host" "server to ping")"
delay="$(get "delay" "delay between pings (default seconds)")"

usage="Usage: $(basename "$0") [quiet]

Repeatedly pings $host to check network connectivity, speaking a
warning if there's a disruption. If $max consecutive packets are lost,
say that we're giving up, send a message to all users, and stop the
script.

If 'quiet' is passed, don't echo usage or say anything before giving
up."

if [ "$1" = "quiet" ]; then
    quiet="true"
else
    echo "$usage" >&2
fi

streak="0"
while true
do
    if ! ping -c1 "$host" &>/dev/null && sleep "$delay"; then
        ((streak++))
        if [ -z "$quiet" ]; then
            say "We lost packet number $streak."
        fi
        if [ "$streak" = "$max" ]; then
            msg="We lost $max packets in a row. We're giving up!"
            echo "$msg" | wall
            say "$msg"
            exit 1
        fi
    else
        streak="0"
    fi
done
