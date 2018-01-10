#!/bin/bash
## scrub-btrfs.sh
# Run btrfs scrub for pre-determined locations and save output to
# date-based filenames.

## Usage: get config-name config-description
# Echoes the requested config back to the script, possibly interacting
# with the user to get initial config if it doesn't exist yet.
get() { get-config "scrub-btrfs/$1" -what-do "$2" || exit 1; }

## Get configurations.
place="$(get "log-dir" "directory where results are logged")"
old_IFS="$IFS"; IFS=$'\n' # Split disk list on newlines, so each element of $disks is a single scrub.
disks=( $(get "disk-list" "list of locations to scrub, each line formatted as 'name location'") )
IFS="$old_IFS"
time="$(date --utc +%F)" # Default to single-day granularity; scrubs don't need to happen extremely frequently.

### CONDENSED EXIT TRAP STUFF COPIED FROM backup-btrfs.sh
exit_traps=()
run-exit-traps() { local i; for i in "${exit_traps[@]}"; do eval "$i"; done; }
trap run-exit-traps EXIT
add-exit-trap() { exit_traps+=("$@"); }

## Usage: $(bold "text to be bolded")
# Makes text bold.
bold() { echo -en "\e[1m$*\e[0m"; }
## Usage: $(bold "text to be bolded")
# Makes text blue.
blue() { echo -en "\e[1;34m$*\e[0m"; }

## Usage: scrubit name location
# Runs btrfs scrub on location and saves results to file based on name.
scrubit() {
    local name="$1"
    local location="$2"
    local file="${place}/${time}_${name}"
    # shellcheck disable=SC2155
    local disp="$(bold "$name") at $(bold "$location")"
    # '-e' may be too broad, but anything stricter risks blocking
    # valid scrubs. The actual 'btrfs scrub' command does the real
    # checking anyway.
    if [ -e "$location" ]; then
        # Check that the scrub result file doesn't already exist from
        # a prior scrub.
        if [ ! -e "$file" ]; then
            # Ensure log folder exists.
            mkdir -p "$(dirname "$file")"
            echo "$(blue Starting btrfs scrub): $disp."
            # ionice -c3: try to force the scrub to use only idle I/O capacity
            # -B: don't background
            # -d: per-device stats
            # -c3: lowest priority (still drastically slows other I/O)
            # We only want sudo for btrfs scrub, not for writing $file.
            # shellcheck disable=SC2024
            sudo ionice -c3 btrfs scrub start -B -d -c3 "$location" > "$file"
            # Back to regularly-scheduled code
            echo "$(blue Finished btrfs scrub:) $disp. Results follow."
            cat "$file"
            echo
        else
            echo "$(blue Skipping btrfs scrub): $disp already scrubbed today."
            echo "$(blue Results of btrfs scrub): $(bold "$file")."
            echo "(Pass '--force' to force a fresh btrfs scrub, but daily is plenty.)"
        fi
    else
        echo "$(blue Skipping btrfs scrub): $disp not found."
    fi
}

handle-backup-service() {
    # Check for and control backup service (see backup-btrfs.sh)
    if which backup-btrfs.installed &>/dev/null; then
        echo "$(blue Stopping btrfs backup service): This prevents I/O contention."
        sudo systemctl stop backup-btrfs.timer
        add-exit-trap "echo '$(blue Re-enabling btrfs backup service).'"
        add-exit-trap "sudo systemctl start backup-btrfs.timer"
        # Also start sudo loop so re-starting the service doesn't need
        # manual reactivation at the script's end (copied from
        # backup-btrfs.sh)
        ( while true; do sleep 50; sudo -v; done; ) &
        add-exit-trap "kill $!"
    fi
}

main() {
    # Use high-precision timestamp if scrub must be forced.
    if [ "$1" = "--force" ]; then
        echo -n "$(blue Using higher-precision time): $(bold "$time") -> "
        time="$(date --utc --iso-8601=s)"
        echo "$(bold "$time") to force fresh btrfs scrubs."
    fi

    # Before starting, make sure that sudo is freshly validated.
    echo "$(blue Entering sudo mode)."
    sudo -v
    handle-backup-service
    local scrub_pids=()
    for line in "${disks[@]}"; do
        old_IFS="$IFS"; IFS=' ' # split line on space, separating the disk name from its path
        # We want $line split into its components.
        # shellcheck disable=SC2086
        set $line
        IFS="$old_IFS"
        scrubit "$1" "$2" &
        scrub_pids+=($!)
    done
    wait "${scrub_pids[@]}" # ... for all the scrubs to finish
}

main "$@"
