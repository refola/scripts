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

### CONDENSED EXIT TRAP STUFF COPIED FROM backup-btrfs.sh
exit_traps=()
run-exit-traps() { local i; for i in "${exit_traps[@]}"; do eval "$i"; done; }
trap run-exit-traps EXIT
add-exit-trap() { exit_traps+=("$@"); }

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
        # ionice -c3: try to force the scrub to use only idle I/O capacity
        # -B: don't background
        # -d: per-device stats
        # -c3: lowest priority (still drastically slows other I/O)
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

handle-backup-service() {
    # Check for and control backup service (see backup-btrfs.sh)
    if which backup-btrfs.installed &>/dev/null; then
        echo "Stopping btrfs backup service before starting scrubs."
        sudo systemctl stop backup-btrfs.timer
        add-exit-trap "echo 'Re-enabling backup service.'"
        add-exit-trap "sudo systemctl start backup-btrfs.timer"
        # Also start sudo loop so re-starting the service doesn't need
        # manual reactivation at the script's end (copied from
        # backup-btrfs.sh)
        ( while true; do sleep 50; sudo -v; done; ) &
        add-exit-trap "kill $!"
    fi
}

main() {
    # Before starting, make sure that sudo is freshly validated.
    echo "Entering sudo mode."
    sudo -v
    handle-backup-service
    local scrub_pids=()
    for line in "${disks[@]}"
    do
        IFS=' ' # split line on space
        # We want $line split into its components.
        # shellcheck disable=SC2086
        set $line
        scrubit "$1" "$2" &
        scrub_pids+=($!)
    done
    wait "${scrub_pids[@]}" # ... for all the scrubs to finish
}

main
