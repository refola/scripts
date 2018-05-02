#!/usr/bin/env bash
# whenami.sh
# Outputs the local time, optionally repeatedly.

if [ -z "$1" ]
then
    date "+%F %H:%M:%S %Z"
elif [ "$1" == "-loop" ]
then
    watch -n1 -p 'date "+%F %H:%M:%S %Z"'
else
    echo "Usage: `basename $0` [-loop]"
    echo "Outputs the local time, repeatedly with \"-loop\"."
fi

