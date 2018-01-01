#!/bin/sh
if [ "$1" != "-q" ]; then
    echo -n "Is volume muted? "
    pactl list sinks | grep -q 'Mute:' | cut -c8-
    echo
    echo "Pass '-q' for quiet (status code only) checking."
fi
pactl list sinks | grep -q 'Mute: yes'
