#!/bin/bash
echo "Setting CPU 0 to minimum frequency so it doesn't get burned out from filesystem waitloop stuff that the kernel is hardcoded to use it for (uses sudo)."
if [ -e /usr/bin/cpupower ]
then
    sudo cpupower --cpu 0 frequency-set -g powersave
fi
if [ -e /usr/bin/cpufreq-set ]
then
    sudo cpufreq-set --cpu 0 -g powersave
fi
exit
