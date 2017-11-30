#!/bin/bash

if [ -z "$1" ] ; then
    echo "Usage: $0 click-count [delay [X-server]]"
    echo "Clicks click-count times, optionally delaying 0.delay seconds between clicks,"
    echo "and on the given X server."
    exit 1
fi

times="$1"

# TODO: figure out current X server automatically
server=$3
if [ -z "$3" ] ; then
    server=":0"
fi



wait=$2
if [ -z "$2" ] ; then
    echo "Clicking $times times, without waiting, sending clicks to X server $server."
    div=100
    for ((x=0; x<$times/$div; x++));
    do
        for ((y=0; y<$div/5; y++));
        do
            xte -x $server "mouseclick 1" "mouseclick 1" "mouseclick 1" "mouseclick 1" "mouseclick 1" #"mouseclick 1" "mouseclick 1" "mouseclick 1" "mouseclick 1" "mouseclick 1"
        done
        sleep 1
    done
else
    echo "Clicking $times times, waiting 0.$wait seconds between clicks, and sending clicks to X server $server."
    for ((x=0; x<$times; x++));
    do
        xte -x $server "mouseclick 1"
        sleep 0.$wait
    done
fi

exit
