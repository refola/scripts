#!/bin/sh
pactl list sinks | grep 'Volume' | grep -v 'Base Volume' | sed -r 's/.* ([0-9.]+)%.*/\1/g'
