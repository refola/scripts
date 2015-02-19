#!/bin/bash
# whenami.sh
# Outputs the local time, optionally repeatedly.

if [ -z "$1" ]
then
	timedatectl status | grep Local | cut -c23-
elif [ "$1" == "-loop" ]
then
	watch -n1 -p 'timedatectl status | grep Local | cut -c23-'
else
	echo "Usage: `basename $0` [-loop]"
	echo "Outputs the local time, repeatedly with \"-loop\"."
fi

