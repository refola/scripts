#!/bin/sh
if [ "$1" != "-q" ]; then
    if pactl list sinks | grep -q 'Mute: yes'; then
        echo "Volume is muted."
    else
        echo "Volume is not muted."
    fi
    echo
    echo "Pass '-q' for quiet (status code only) checking."
fi
pactl list sinks | grep -q 'Mute: yes'
