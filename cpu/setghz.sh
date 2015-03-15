#!/bin/bash

if [ -z "$1" ]
then
	echo "Usage: $(basename $0) maxGHz"
	echo "Sets the CPU to run up to the given frequency."
	exit 1
fi

freq="${1}GHz"

echo "Setting CPU to $freq"

if [ -e /usr/bin/cpupower ]
then
	sudo cpupower frequency-set -g ondemand --max "$freq"
fi
if [ -e /usr/bin/cpufreq-set ]
then
	sudo cpufreq-set -g ondemand --max "$freq"
fi

exit
