#!/bin/bash
## packet-loss-alerter.sh
# Keep pinging a known reliable host, produce an audible warning each
# time a packet is lost, and produce a more annoying warning and exit
# when the maximum number of consecutive lost packets is reached.

max="5"
host="google.com"
delay="5"

usage="Usage: $(basename "$0") [max]

Repeatedly pings $host to check network connectivity, speaking a
warning if there's a disruption. If max consecutive packets are lost,
say that we're giving up, send a message to all users, and stop the
script.

Without max being passed, this script defaults to a limit of $max
consecutive lost packets. Setting max to anything that isn't a
positive integer disables the excessive packet loss check, making this
script act like packet-loss-logger, only speaking instead of saving
the messages."

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
        say "We lost packet number $streak."
        if [ "$streak" = "$max" ]
        then
            msg="We lost $max packets in a row. We're giving up!"
            echo "$msg" | wall
            say "$msg"
            exit 1
        fi
    else
        streak="0"
    fi
done
