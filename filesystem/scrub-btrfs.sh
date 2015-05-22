#!/bin/bash
## scrub-btrfs.sh
# Run btrfs scrub for pre-determined locations and save output to
# date-based filenames.

PLACE="/home/mark/doc/text/tech/hardware/core-plus/btrfs-info"
DATE="$(date --utc +%F)" # Get current UTC date

# List of scrubs to run, in the "name location" format.
DISKS="
internal /
external /run/media/mark/OT4P/
"

## Usage: scrubit name location
# Runs btrfs scrub on location and saves results to file based on name.
scrubit() {
    local NAME="$1"
    local LOCATION="$2"
    local FILE="${PLACE}/${DATE}_scrub_${NAME}"
    local DISP="$NAME at $LOCATION"
    echo "Starting btrfs scrub for $DISP."
    sudo btrfs scrub start -B -d "$LOCATION" > "$FILE"
    echo
    echo "Scrub finished for $DISP. Results are as follows:"
    cat "$FILE"
}

# Before starting, make sure that sudo is freshly validated.
echo "Entering sudo mode."
sudo -v
IFS=$'\n' # split DISKS on newline
for line in $DISKS
do
    IFS=' ' # split line on space
    set $line
    scrubit "$1" "$2" &
done
wait # ... for all the scrubs to finish
