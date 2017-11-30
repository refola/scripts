#!/bin/bash
## trackpoint-cfg.sh
# Set trackpoint configuration to my preferences.

# Note: There's some sort of intermittent error where the trackpoint
# often resets all of its values when trying to change one value.
# Jiggling it seems to have an effect sometimes (~30-60%?), but
# clicking seems more reliable (~70-80%?). In particular, a quick
# click before changing a value seems to (I feel ~50% confidence of
# this effect being real) set the trackpoint into "active" mode, and a
# quick click during the `secho` often (~70-80% of the time?) makes
# the `secho` finish immediately and successfully.

prefix="/sys/devices/platform/i8042/serio1/serio2"
places=()

set_val() {
    sudo -v
    /bin/echo -e "Setting \e[1m$1=$2\e[0m via\n\t\e[1mecho \"$2\" | sudo tee \"$prefix/$1\"\e[0m"
    echo -e "\e[1;93mPlease quickly click again....\e[0m" # seems to be the way to fix the problem...
    sleep 1 # It seems there's some sort of synchronization issue and that this kinda helps?
    secho "$2" "$prefix/$1"
    ecat "$prefix/$1"
    places=("${places[@]}" "$prefix/$1")
    sleep 1 # It seems there's some sort of synchronization issue and that this kinda helps?
}

sudo -v
echo -e "\e[1;93mPlease click quickly....\e[0m"
sleep 1
#set_val inertia 6
set_val speed 255
set_val sensitivity 255
set_val drift_time 13
echo -e "\e[1;93mDone! Hopefully the change stuck....\e[0m"
ecat "${places[@]}"
