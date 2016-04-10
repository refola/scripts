#!/bin/sh

while true; do
    # get amount of free memory
    available="$(grep MemAvailable /proc/meminfo | egrep -o '[0-9]+')"
    if [ $? != 0 ]; then
        echo "$0: Could not get available memory." | write "$USER"
        sleep 10
    fi
    # convert from KB to MB
    available_mb=$((available/1000))
    # check that there's at least 3 GB left
    if [ "$available_mb" -lt "3000" ]; then
        echo "Low memory! We're down to $available_mb MB!" | write "$USER"
        sleep 10
    fi
    sleep 1
done
