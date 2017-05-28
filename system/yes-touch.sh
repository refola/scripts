#!/bin/sh
# yes-touch.sh
# Enable touch input, at least on a ThinkPad X220 Tablet.
xinput set-prop 'Wacom ISDv4 E6 Finger touch' 'Device Enabled' 1
xinput set-prop 'SynPS/2 Synaptics TouchPad' 'Device Enabled' 1
