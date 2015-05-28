#!/bin/bash
# Cache a bunch of regularly-used folders for faster future access

# Folders to cache. Sorted alphabetically because they'll be chaotically parallelized anyway.
folders="
/bin
/home/$USER/code
/home/$USER/doc
/home/$USER/media/img/wallpaper
/home/$USER/prog
/home/$USER/refola
$HOME
/lib
/lib64
/sbin
/usr/bin
/usr/lib
/usr/lib64
/usr/sbin
/usr/share/applications
/usr/share/icons
"

sec=15
if [ -z "$1" ]
then
    echo "You can optionally tell this script how long to wait before caching things. Try 0 for instant gratification."
else
    sec="$1"
fi

echo "Waiting $sec seconds before caching stuff...."
sleep "$sec"
echo "Caching a bunch of commonly-used folders...."

dofolder() {
    if [ -d "$folder" ]
    then
	cd "$folder"
	echo "Caching folder $folder."
	(time "cache-folder > /dev/null") 2>&1 | grep -v user | grep -v sys | grep -v "^$" | grep -v "Permission denied"
    else
	echo "Folder doesn't exist: $folder"
    fi
}

# Times:
# everything at once: 1m38.769s
# one thing at a time: 2m32.525s, 2m33.286s, 2m26.173s
# unbalanced split groups: 1m47.944s+
# balanced split (mixed): 1m59.498s (folders2 finished 5s faster)
# balanced split (fast first): 1m50.917s (folders1 finished 2s faster)
# balanced split (slow first): 1m50.609s (folders1 finished 2s faster)
# home-system split (fast first): 1m53.554s (folders2 finished 9s faster)
# Conclusion: It's faster to have the system chaotically try to do everything at once.
# everything at once again: 1m54.031s, 1m32.217s, 1m52.501s, 1m53.153s
# Second conclusion: It doesn't matter much....
# running "du -sh /bin /home/mark /lib /lib64 /sbin /usr" first: 1m53.004s, 1m30.328s, 1m35.333s, 1m26.017s
# Conclusion 3: Something random is going on....
for folder in $folders
do
    dofolder "$folder" & # Fastest way. See times above.
done

exit
