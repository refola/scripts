#!/bin/sh
pactl set-sink-volume 0 "+${1-5}%"
