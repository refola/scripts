#!/bin/bash
## scrub-btrfs.sh
# Run btrfs scrub for pre-determined locations and save output to
# date-based filenames.

place="/home/mark/doc/text/tech/hardware/core-plus/btrfs-info"
today="$(date --utc +%F)" # Get current UTC date

# List of scrubs to run, in the "name location" format.
disks="
internal /mnt
external /run/media/mark/OT4P
external /run/media/sampla/OT4P
"

## Usage: scrubit name location
# Runs btrfs scrub on location and saves results to file based on name.
scrubit() {
    local name="$1"
    local location="$2"
    local file="${place}/${today}_scrub_${name}"
    local disp="$name at $location"
    if [ -d "$location" ]
    then
	echo "Starting btrfs scrub for $disp."
	# We only want sudo for btrfs scrub, not for writing $file.
	# shellcheck disable=SC2024
	sudo btrfs scrub start -B -d "$location" > "$file"
	echo
	echo "Scrub finished for $disp. Results are as follows:"
	cat "$file"
    else
	echo "Could not find disk $name at $location."
    fi
}

# Before starting, make sure that sudo is freshly validated.
echo "Entering sudo mode."
sudo -v
IFS=$'\n' # split disks on newline
for line in $disks
do
    IFS=' ' # split line on space
    # We want $line split into its components.
    # shellcheck disable=SC2086
    set $line
    scrubit "$1" "$2" &
done
wait # ... for all the scrubs to finish
