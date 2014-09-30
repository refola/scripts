#!/bin/bash
echo "Setting CPUs to ondemand frequency, but limited to only 2 GHz because ambiant temperatures are too hot (uses sudo)."
if [ -e /usr/bin/cpupower ]
then
	sudo cpupower frequency-set -g ondemand --max 2GHz
fi
if [ -e /usr/bin/cpufreq-set ]
then
	sudo cpufreq-set -g ondemand --max 2GHz
fi

# See message echoed by savecorezero.sh.
savecorezero

exit
