#!/bin/sh
x='Default Sink: '
sink="$(pactl info | grep "$x" | cut "-c$((${#x}+1))-")"
pactl set-sink-mute "$sink" toggle
