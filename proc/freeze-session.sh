#!/bin/bash
# Lock the screen and do not allow it to be unlocked until 6 hours have passed.

uptime

#time="5s" # for testing
time="6h"
lproc="kscreenlocker" # locking process name
# list command line access programs first
apps="
yakuake
konsole
chrome
firefox
kwrite
kate
dolphin
okular
"

pause(){
    procs=`ps -U $(whoami) -o "pid comm" | grep $1 | sed "s/[^0-9]//g"`
    echo "PIDs for $1: $procs"

    echo "Pausing process(es)."
    for pid in $procs
    do
	kill -s SIGSTOP $pid
    done
}
unpause(){
    procs=`ps -U $(whoami) -o "pid comm" | grep $1 | sed "s/[^0-9]//g"`
    echo "PIDs for $1: $procs"

    echo "Unpausing process(es)."
    for pid in $procs
    do
	kill -s SIGCONT $pid
    done
}
lock(){
    echo "Starting locker"
    #qdbus org.freedesktop.ScreenSaver /ScreenSaver Lock&
    /usr/lib/kde4/libexec/kscreenlocker --forcelock
    echo "Locker finished"
    uptime
}
pauseapps(){
    echo "Pausing common apps to conserve CPU and bandwidth"
    for app in $apps
    do
	pause $app
    done
}
resumeapps(){
    echo "Unpausing apps"
    for app in $apps
    do
	unpause $app
    done
}

lock&
pauseapps # do this before locking to leave CPU power for locking to finish
sleep 1 # give locker time to lock; insecurely assumes that 1 second is enough
pause $lproc # can't tell the locker to unlock when it's paused
echo "Apps paused and system locked; sleeping for $time."
sleep $time
unpause $lproc
resumeapps

uptime

exit
