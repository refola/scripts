#!/bin/bash
# Pause all of the current user's processes that match the given name.

# Make sure the process name is passed.
if [ -z "$1" ]
then
	echo "Usage: `basename $0` process_name [seconds]"
	echo "This will pause all processes named process_name that are owned by the script's user for the given number of seconds or 60 seconds if seconds is not given."
	exit 1
fi

sec=$2

if [ -z "$2" ]
then
	sec=60
fi

procs=`ps -U $(whoami) | grep $1 | sed "s/?.*//g" | sed "s/[^0-9]//g"`
echo "PIDs for $1: $procs"

echo "Pausing process(es)."
for pid in $procs
do
	kill -s SIGSTOP $pid
done

echo "Process(es) paused; sleeping for $sec seconds."
sleep $sec

echo "Unpausing process(es)."
for pid in $procs
do
	kill -s SIGCONT $pid
done

exit
