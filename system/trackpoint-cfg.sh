#!/bin/sh
## trackpoint-cfg.sh
# Set trackpoint configuration to my preferences.

set_val() {
    echo "$2" | sudo tee "/sys/devices/platform/i8042/serio1/serio2/$1"
}

set_val inertia 6
set_val drift_time 13
set_val sensitivity 197
set_val speed 197
