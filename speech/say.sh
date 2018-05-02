#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Usage: $(basename "$0") words [...]"
    echo "Uses a speech synthesizer to speak the given words."
    exit 1
fi

if [ ! -e "$(which spd-say)" ]; then
    echo -e "Error: Could not find \e[1mspd-say\e[0m command."
    pkg="speech-dispatcher"
    echo -e "Searching for \e[1m$pkg\e[0m package to get \e[1mspd-say\e[0m."
    if pm s "$pkg"; then
        echo -e "Please run \e[1mpm in \e[3mpackage-name\e[0m to install the right package."
    fi
    exit 1
fi

words="$*" # Collect all the words into a single variable.
echo "$words" # Show what is being said.
spd-say -w "$words" # Say it.
