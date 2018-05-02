#!/usr/bin/env bash
## save-smart-info.sh
# Save SMART info for pre-determined locations and save output to
# date-based filenames.

if ! which smartctl &>/dev/null; then
    echo "Error: Could not find 'smartctl'."
    echo "Please install it, e.g., with 'pm in smartmontools'."
    exit 1
fi

place="$(get-config "save-smart-info/log-dir" -what-do "directory where SMART statuses are saved")" || exit 1
# Split disk list on newlines.
IFS=$'\n'
disks=( $(get-config "save-smart-info/disk-list" -what-do "list of disks to check, each line formatted as 'name location'") ) || exit 1
today="$(date --utc +%F)" # Get current UTC date

## Usage: smart name location
# Run smartctl on location and save results to file based on name.
smart() {
    local name="$1"
    local location="$2"
    local file="${place}/${today}_smart_${name}"
    local disp="$name at $location"
    if [ -b "$location" ]; then
        mkdir -p "$(dirname "$file")" # Ensure log folder exists.
        sudo smartctl -x "$location" > "$file" # Save SMART info to (hopefully-new) file.
        echo "Saved SMART info for $name."
    else
        echo "Could not find disk $name at $location."
    fi
}

for line in "${disks[@]}"
do
    IFS=' ' # split line on space
    # We want $line split into its components.
    # shellcheck disable=SC2086
    set $line
    smart "$1" "$2"
done
