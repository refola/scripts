#!/bin/bash
echo "Setting CPUs to ondemand frequency (uses sudo)."
if [ -e /usr/bin/cpupower ]
then
        sudo cpupower frequency-set -g ondemand
fi
if [ -e /usr/bin/cpufreq-set ]
then
        sudo cpufreq-set -g ondemand
fi

# See message echoed by savecorezero.sh.
savecorezero

exit
