#!/usr/bin/env bash
# Lock the screen and do not allow it to be unlocked until the given time has elapsed.

# Make sure the number of seconds is given.
if [ -z "$1" ]
then
    echo "Usage: `basename $0` seconds [die]"
    echo "This will lock the screen and pause the screen-locking process for the given number of seconds."
    echo "If \"die\" is specified after seconds, this will also kill the screen-locker after time has elapsed."
    echo
    echo "Bugs:"
    echo " * This only works on KDE 4.x."
    echo " * This makes insecure assumptions (see comments in source for details)."
    exit 1
fi

sec=$1
lproc="kscreenlocker" # locking process name

lock(){
    qdbus org.freedesktop.ScreenSaver /ScreenSaver Lock
}

echo "Locking screen."
lock& # doesn't give proper feedback, so insecure assumptions are made

echo "Pausing locker."
while [ -z "$pid" ]
do
    sleep 0.5 # wait for locker to spawn before seeking it
    pid=`ps -U $(whoami) | grep $lproc | sed "s/?.*//g" | sed "s/[^0-9]//g"`
    echo "pid: $pid"
done

sleep 0.5 # let the locker finish locking before pausing it - assuming success after 0.5 seconds is insecure
kill -s SIGSTOP $pid

echo "Locker paused; sleeping for $sec seconds."
sleep $sec

echo "Unpausing locker"
kill -s SIGCONT $pid

if [ "$2" = "die" ]
then
    kill -s TERM $pid
fi

exit
