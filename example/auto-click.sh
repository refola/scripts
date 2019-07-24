#!/usr/bin/env bash

USAGE="Usage: $0 click-count [delay [X-server]]

Clicks 'click-count' times, optionally delaying 'delay' time between
clicks, and on the given 'X-server'.

Note: While usable for basic tasks, this is only an example
script. Actual auto-clicking is likely better done by using 'xte
\"mouseclick 1\"' inside your own logic."

if [ -z "$1" ] ; then
    echo "$USAGE"
    exit 1
fi

if ! which xte &>/dev/null; then
    echo "Error: 'xte' command not found. Try installing 'xautomation' or similar."
    exit 1
fi

times="$1"

server=$3
if [ -z "$3" ] ; then
    # Get from environment, else fall back to default
    server="${DISPLAY-:0}"
fi

wait=$2
if [ -z "$2" ] ; then
    # Click as fast as possible for some unspecified task -- edit for
    # whatever gets meaningful clicks to your target at your desired
    # rate.
    echo "Clicking $times times, without waiting, sending clicks to X server $server."
    div=100 # divisor for how large the groups of clicks click-count
            # should be split into. BUG: any remainder is silently
            # skipped
    for ((x=0; x<times/div; x++)); do
        # '5' is a hard-coded smaller divisor; the delay of invoking
        # 'xte' can stabilize the target's receiving and processing of
        # the clicks
        for ((y=0; y<div/5; y++)); do
            xte -x "$server" "mouseclick 1" "mouseclick 1" "mouseclick 1" "mouseclick 1" "mouseclick 1" #"mouseclick 1" "mouseclick 1" "mouseclick 1" "mouseclick 1" "mouseclick 1"
        done
        sleep 1
    done
else
    echo "Clicking $times times, waiting 0.$wait seconds between clicks, and sending clicks to X server $server."
    for ((x=0; x<times; x++)); do
        xte -x "$server" "mouseclick 1"
        sleep "$wait"
    done
fi
