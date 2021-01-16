#!/bin/sh
# restart-pulseaudio.sh

# kill existing pa server if running
pulseaudio --kill &&
    sleep 1 # and pause a moment for audio device to free or whatever

# start a fresh pa daemon without accumulated glitchiness
pulseaudio --daemonize=true
