#!/bin/bash
localfolders="
.cache/banshee-1
.cache/dconf
.cache/efreet
.cache/evas_gl_common_shaders
.cache/fontconfig
.cache/gstreamer-1.0
.cache/mate
.cache/media-art
.cache/openbox
.cache/sessions
.cache/Thunar
.cache/transmission
.cache/vlc
.cache/xfce4
.dvdcss
.nv/GLCache
.thumbnails
.kde4/share/apps/amarok/albumcovers/cache
.kde4/share/apps/gwenview/recentfolders
.kde4/share/apps/okular/docdata
.kde4/share/apps/RecentDocuments
"
#.kde4/share/applnk

localfiles="
.kde4/share/config/konq_history
.local/share/recently-used.xbel
.xsession-errors
.xsession-errors-:1
.xsession-errors-:2
"
#.kde4/share/config/kolourpaintrc

netfolders="
.cache/chromium
.cache/google-chrome
.cache/mozilla
jagexcache
"

netfiles="
"

folders() {
    local IFS=$'\n'
    for folder in $1
    do
	if [ -d "$HOME/$folder" ]
	then
	    echo "Removing folder: $folder"
	    rm -r "${HOME:?}/${folder:?}/"
	    #	else
	    #		echo "Folder doesn't exist: $folder"
	fi
    done
}

files() {
    local IFS=$'\n'
    for file in $1
    do
	if [ -f "$HOME/$file" ]
	then
	    echo "Removing file: $file"
	    rm "${HOME:?}/${file:?}"
	    #	else
	    #		echo "File doesn't exist: $file"
	fi
    done
}

echo "Cleaning caches, histories, et cetera."

folders "$localfolders"
files "$localfiles"

# Disable when at a place with limited Internet access.
if [ "$1" == "all" ]
then
    folders "$netfolders"
    files "$netfiles"
else
    echo "Skipping network cache clearing. Use \"$0 all\" to clear them too."
fi

#echo "Running other commands...."
#echo "Running profile-cleaner to shrink SQLite databases for Chromium and Firefox."
#profile-cleaner c
#profile-cleaner f

exit
