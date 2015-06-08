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
    if [ -d "$folder" ]
    then
	duration="$( (time cache-folder "$folder" > /dev/null) 2>&1 | grep -v user | grep -v sys | grep -v "^$" | grep -v "Permission denied")"
        duration="${duration/#real/}"
        echo -e "Finished $folder in $duration."
    else
	echo "Folder doesn't exist: $folder"
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
        # setup, everything at once has been tested as faster than doing
        # it serially or with forking two serial processes that each
        # handle half the work.
        cache-one "$folder" &
    done
    wait # ... for background caching to finish
    echo "Done! ^.^"
}

cache-em-all # Gotta...
