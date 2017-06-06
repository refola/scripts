#!/bin/bash
# touch-control.sh
##
# Enable/disable touch input, at least on a ThinkPad X220 Tablet and
# the distros I've used on it.

name="$(basename "${0/%.sh/}")" # get name this script was ran under
usage="$name value
  or:  no-touch
  or:  yes-touch

Attempt to enable or disable touchpad and touchscreen input. When ran
as '$name' the script requires either 0 (disable) or 1
(enable) to be passed so it knows which to do. The other invocations
respectively disable and enable touch input."

value= # 0=disable, 1=enable
if [ -n "$1" ]; then
    value="$1"
else
    case "$name" in
        no-touch ) value=0 ;;
        yes-touch ) value=1 ;;
        * ) echo "$usage"
            exit 1
            ;;
    esac
fi

devices=(
    'Wacom ISDv4 E6 Finger touch' # Kubuntu 17.04
    'Wacom ISDv4 E6 Finger' # Chakra Linux
    'SynPS/2 Synaptics TouchPad'
)

for dev in "${devices[@]}"; do
    xinput set-prop "$dev" "Device Enabled" "$value"
done
