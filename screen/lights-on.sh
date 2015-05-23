#!/bin/bash
# lightsOn.sh

# Copyright © 2011 iye.cba at gmail com, © 2013 Mark Haferkamp
# Original url: https://github.com/iye/lightsOn
# The original script is licensed under GNU GPL version 2.0 or above.
# I (Mark) don't like licenses being longer than the thing they
# cover, so I'm explicitly not specifying a license for my changes.

# This has been greatly simplified from the original to
# (a) actually work with KDE4, which has been out for like 5 years now,
# (b) simplify it so I can sorta understand it, and
# (c) disable the screensaver, et cetera regardless of which programs are running.

# Description: Bash script that unconditionally prevents the
# screensaver and display power management (DPMS) to be activated
# on KDE, stopping kscreensaver.

# HOW TO USE: Start the script. It simulates user activity every
# 50 seconds, preventing power management, screensaver, etc.

delayScreensaver()
{
    # Tell KDE that there's been user activity so it doesn't activate the screensaver, etc.
    qdbus org.freedesktop.ScreenSaver /ScreenSaver SimulateUserActivity > /dev/null

    # Commented out to see if it actually makes a difference.
    # 	#Check if DPMS is on. If it is, deactivate and reactivate again. If it is not, do nothing.    
    # 	dpmsStatus=`xset -q | grep -ce 'DPMS is Enabled'`
    # 	if [ $dpmsStatus == 1 ];then
    # 		xset -dpms
    # 		xset dpms
    # 	fi
}

while true
do
    delayScreensaver
    sleep 50
done
