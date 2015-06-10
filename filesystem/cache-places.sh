#!/bin/bash
# Cache a bunch of regularly-used folders for faster future access

folders=( $(get-config "cache-places/folders" "list of folders to cache") )

sec=15
if [ -z "$1" ]
then
    echo "You can optionally tell this script how long to wait before"
    echo "caching things. Try 0 for instant gratification."
else
    sec="$1"
fi

if [ "$sec" != "0" ]
then
    echo "Waiting $sec seconds before caching stuff...."
    sleep "$sec"
fi

# Caches a single folder, wrapping the "cache-folder" command for prettiness.
cache-one() {
    if [ -d "$folder" -a ! -h "$folder" ]
    then
        size="$(du -sh "$folder" 2>/dev/null)"
        size="${size%$'\t'$folder}"
	duration="$( (time cache-folder "$folder" > /dev/null) 2>&1 | grep -v user | grep -v sys | grep -v "^$" | grep -v "Permission denied")"
        duration="${duration#real$'\t'}"
        echo -e "Took $duration to cache $size in $folder."
    else
        if [ -h "$folder" ]
        then
            echo "Skipping symlink: $folder"
        else
            echo "Folder doesn't exist: $folder"
        fi
    fi
}

# Caches every folder in the list.
cache-em-all() {
    echo "Caching configured list of commonly-used folders. This may take a while...."
    for folder in "${folders[@]}"
    do
        # Replace variable references in the folder.
        folder="$(eval echo "$folder")"
        # On the developer's dual-spinning-platter-disk btrfs RAID 1
        # setup, everything at once has been tested as faster than
        # doing it serially or with forking two serial processes that
        # each handle half the work. Note that HDD I/O is at only a
        # trickle during this time, so the disks are spending most of
        # the time waiting for the right data to be under the heads
        # and there's tons of room for performance improvement (e.g.,
        # something system-level that puts the files in sequence).
        cache-one "$folder" &
    done
    wait # ... for background caching to finish
    echo "Done! ^.^"
}

cache-em-all # Gotta...
