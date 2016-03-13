#!/bin/bash
## scrub-btrfs.sh
# Run btrfs scrub for pre-determined locations and save output to
# date-based filenames.

get() { get-config "scrub-btrfs/$1" -what-do "$2" || exit 1; }
place="$(get "log-dir" "directory where results are logged")"
# Split disk list on newlines.
IFS=$'\n'
disks=( $(get "disk-list" "list of locations to scrub, each line formatted as 'name location'") )
today="$(date --utc +%F)" # Get current UTC date

## Usage: scrubit name location
# Runs btrfs scrub on location and saves results to file based on name.
scrubit() {
    local name="$1"
    local location="$2"
    local file="${place}/${today}_scrub_${name}"
    local disp="$name at $location"
    if [ -d "$location" ]
    then
        # Ensure log folder exists.
        mkdir -p "$(dirname "$file")"
        echo "Starting btrfs scrub for $disp."
        # ionice -c3: workaround for btrfs-progs not honoring its -c3
        # -B: don't background
        # -d: per-device stats
        # -c3: lowest priority (doesn't do anything as of btrfs-progs 4.3.1)
        # We only want sudo for btrfs scrub, not for writing $file.
        # shellcheck disable=SC2024
        sudo ionice -c3 btrfs scrub start -B -d -c3 "$location" > "$file"
        # Back to regularly-scheduled code
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
for line in "${disks[@]}"
do
    IFS=' ' # split line on space
    # We want $line split into its components.
    # shellcheck disable=SC2086
    set $line
    scrubit "$1" "$2" &
done
wait # ... for all the scrubs to finish
