#!/usr/bin/env bash
# Cache a bunch of regularly-used folders for faster future access

cfg="cache-places/folders"
# The IFS and extra parentheses turn $folders into an array.
IFS=$'\n'
folders=( $(get-config "$cfg" \
    -what-do "list of folders to cache" \
    -var-rep ) ) || exit 1

delay="15s"
fork=''
cfg_path="$(get-config "$cfg" -path)"
usage="$(basename "$0") [delay] [-fork]

Caches everything listed in ${cfg_path/#$HOME/'~'}, waiting 'delay'
(as accepted by the 'sleep' command; default is seconds) before
starting (default=$delay), and forking if '-fork' is passed. Forking
is probably only useful if you have replicating RAID or a solid state
drive, since random accesses tend to be slower on spinning-rust
drives."

# Parse arguments
if [ -z "$1" ]; then
    echo "$usage" # Accept no-arg default, but notify user.
else
    while [ -n "$1" ]; do
        if [ "$1" = "$(echo "$1" | egrep "^[0-9]+[smhd]?$")" ]; then
            delay="$1"
        elif [ "$1" = "-fork" ]; then
            fork="true"
        else
            echo "Unknown argument '$1'. Aborting."
            echo "$usage"
            exit 1
        fi
        shift
    done
fi

# Make implicit unit of seconds explicit.
if [ "${delay/%[smhd]/}" = "$delay" ]; then
    delay="${delay}s"
fi

# Notify of delay iff delay happens.
if [ "${delay/%[smhd]/}" != "0" ]; then
    echo "Waiting $delay before caching stuff...."
    sleep "$delay"
fi

# Caches a single folder, wrapping the "cache-folder" command for prettiness.
cache-one() {
    local folder="$1"
    if [ -d "$folder" -a ! -h "$folder" ]; then # check that it's a folder and not a symlink
        size="$(du -sh "$folder" 2>/dev/null)"
        size="${size%$'\t'$folder}"
        export TIMEFORMAT="%Es" # Make Bash's time command show only ellapsed time.
        duration="$( (time cache-folder "$folder" > /dev/null) 2>&1 | grep -v 'Permission denied')"
        echo -e "Took $duration to cache $size in $folder."
    else
        if [ -h "$folder" ]; then
            echo "Skipping symlink: $folder"
        else # the "! -d" case
            echo "Folder doesn't exist: $folder"
        fi
    fi
}

# Caches every folder in the list.
cache-em-all() {
    echo "Caching configured list of commonly-used folders. This may take a while...."
    for folder in "${folders[@]}"; do
        if [ -z "$fork" ]; then
            cache-one "$folder"
        else
            cache-one "$folder" &
        fi
    done
    wait # ... for background caching to finish
    echo "Done! ^.^"
}

cache-em-all # Gotta...
