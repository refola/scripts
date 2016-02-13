#!/bin/bash
# screenshot.sh
# Version: 0.1 
# Author: Marco R. Gazzetta
# Date: 2013-11-26
# License: "GNU/LGPL" <http://www.gnu.org/licenses/lgpl.html>
# Source: http://www.mrgazz.com/computers/computers-mainmenu-138/howto/fixing-ksnapshot-and-programming-shell
# WebCite: http://www.webcitation.org/6WRh37XHO
# Description: This is code copied from the given citation's blog post to use ksnapshot to take a snapshot and save the image without requiring user interaction. This may not match the download linked to in the site because I couldn't access it due to a log-in wall.

# first, find the running instance of ksnapshot
wasrunning="yes"
pid="`pidof -s ksnapshot`"
if [ -z "$pid" ]
then
    wasrunning=""
    ksnapshot &
    pid="`pidof -s ksnapshot`"
fi
if [ -z "$pid" ]
then
    echo "Could not start ksnapshot (Unknown error). Exiting..."
    exit 1
fi
# wait for the service to come online
e_val="dummy"
while [ "$e_val" ]
do
    e_val=`qdbus org.kde.ksnapshot-$pid /KSnapshot org.freedesktop.DBus.Peer.Ping 2>&1`
    sleep 1
done

# if there is no default format, set PNG
url="`qdbus org.kde.ksnapshot-$pid /KSnapshot org.kde.ksnapshot.url`"
ext="${url##*.}"
if [ -z "$ext" ]
then
    echo "Setting url $url to PNG"
    qdbus org.kde.ksnapshot-$pid /KSnapshot org.kde.ksnapshot.setUrl $url.png
fi

# find the window ID
win_id=`xwininfo -root -tree | awk '/KSnapshot/ {print $1}'`
# modified="`xwininfo -id $win_id | awk -F \" '{print $2}'`"
modified=`xprop -id $win_id | grep NET_WM_NAME | grep modified`
mode=`qdbus org.kde.ksnapshot-$pid /KSnapshot org.kde.ksnapshot.grabMode`
if [ "$modified" ]
then
    # save if it already says modified, so we know we have to wait for the string to show again
    url=`qdbus org.kde.ksnapshot-$pid /KSnapshot org.kde.ksnapshot.url`
    qdbus org.kde.ksnapshot-$pid /KSnapshot org.kde.ksnapshot.slotSave
    # but discard the saved grab if not already running and mode other than 0
    if [ -z "$wasrunning"  -a $mode -ne 0 ]
    then
        qdbus org.kde.ksnapshot-$pid /KSnapshot org.kde.ksnapshot.setURL "$url"
    fi
fi

# grab a new screenshot if it was already running or the mode is not 0
if [ "$wasrunning" -o $mode -ne 0 ]
then
    qdbus org.kde.ksnapshot-$pid /KSnapshot org.kde.ksnapshot.slotGrab

    # wait for the window to report the grab is done
    modified=""
    while [ -z "$modified" ]
    do
        modified="`xprop -id $win_id | grep 'NET_WM_NAME.*modified'`"    sleep 1
    done

    # save that shot in the preselected directory/format
    qdbus org.kde.ksnapshot-$pid /KSnapshot org.kde.ksnapshot.slotSave
fi

# shut down if we started it
if [ -z $wasrunning ]
then
    qdbus org.kde.ksnapshot-$pid /KSnapshot org.kde.ksnapshot.exit
fi
