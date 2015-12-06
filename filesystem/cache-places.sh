#!/bin/bash
# Cache a bunch of regularly-used folders for faster future access

cfg="cache-places/folders"
# The IFS and extra parentheses turn $folders into an array.
IFS=$'\n'
folders=( $(get-config "$cfg" \
                       -what-do "list of folders to cache" \
                       -var-rep ) ) || exit 1

sec=15
fork=''
cfg_path="$(get-config "$cfg" -path)"
usage="$(basename "$0") [delay] [-fork]

Caches everything listed in ${cfg_path/#$HOME/'~'},
waiting 'delay' seconds before starting (default=$sec), and forking if
'-fork' is passed."

if [ -z "$1" ]
then
    echo "$usage"
else
    sec="$1"
    if [ -n "$2" -a "$2" != "-fork" ]
    then
        echo "$usage"
        exit 1
    elif [ "$2" = "-fork" ]
    then
        fork="true"
    fi
fi

if [ "$sec" != "0" ]
then
    echo "Waiting $sec seconds before caching stuff...."
    sleep "$sec"
fi

# Caches a single folder, wrapping the "cache-folder" command for prettiness.
cache-one() {
    if [ -d "$folder" -a ! -h "$folder" ] # check that it's a folder and not a symlink
    then
        size="$(du -sh "$folder" 2>/dev/null)"
        size="${size%$'\t'$folder}"
        export TIMEFORMAT="%Es" # Make Bash's time command show only ellapsed time.
	      duration="$( (time cache-folder "$folder" > /dev/null) 2>&1 | grep -v 'Permission denied')"
        echo -e "Took $duration to cache $size in $folder."
    else
        if [ -h "$folder" ]
        then
            echo "Skipping symlink: $folder"
        else # the "! -d" case
            echo "Folder doesn't exist: $folder"
        fi
    fi
}

# Caches every folder in the list.
cache-em-all() {
    echo "Caching configured list of commonly-used folders. This may take a while...."
    for folder in "${folders[@]}"
    do
        if [ -z "$fork" ]
        then
            cache-one "$folder"
        else
            cache-one "$folder" &
        fi
    done
    wait # ... for background caching to finish
    echo "Done! ^.^"
}

cache-em-all # Gotta...
