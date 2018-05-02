#!/usr/bin/env bash
# Phone system backup script, using a delete-and-copy method via
#  "adb pull [source] [destination]".

# Figure out where to backup to.
TO="/home/$USER/phone/system-backup"
LS_CMD="adb shell ls -a /"

# Places that can be backed up normally....
SAFE="
acct
boot.txt
cache
config
d
data
default.prop
etc
init
init.cm.rc
init.goldfish.rc
init.rc
init.superuser.rc
init.trace.rc
init.usb.rc
init.victory.rc
init.victory.usb.rc
lpm.rc
sbin
system
ueventd.goldfish.rc
ueventd.rc
ueventd.victory.rc
vendor
"

# Places that shouldn't be backed up with this script
UNSAFE="
dev     # Contains raw SD card data.
mnt     # Contains SD card.
proc    # Running stuff.
sdcard  # Points to SD card.
storage # Contains SD card.
sys     # Makes phone reboot at \"sys/devices/platform/s5pv210-uart.0/clock_source\".
"

pull() {
    echo "adb pull $1 $TO/$1"
    adb pull "$1" "$TO/$1"
}

backup() {
    adb root
    sleep 5 # let adb have some time....
    if [ -d "$TO.bak" ]
    then
        echo "Deleting backup at $TO.bak"
        rm -r "$TO.bak"
    fi
    if [ -d "$TO" ]
    then
        echo "Backing up existing $TO to $TO.bak"
        mv "$TO" "$TO.bak"
    fi
    echo "Backing up system to $TO."
    mkdir "$TO"

    for PLACE in $SAFE
    do
        pull "$PLACE"
    done
}

time backup

echo -e "\nDone backing up select system files on phone, as indicated above. Please see output of \"$LS_CMD\" (shown below) to see all potential places to back up.\n"
$LS_CMD
echo -e "\nNote that the following places are intentionally skipped by this script for the given reasons: \n$UNSAFE"

exit
