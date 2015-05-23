#!/bin/bash
echo "Setting CPUs to minimum frequency (uses sudo)."
if [ -e /usr/bin/cpupower ]
then
    sudo cpupower frequency-set -g powersave
elif [ -e /usr/bin/cpufreq-set ]
then
    sudo cpufreq-set -g powersave
else
    echo "CPU frequency-controlling command not found!"
fi

cpu-save-core-zero

exit
