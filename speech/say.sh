#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $(basename "$0") words that you want spoken"
    echo "Uses a speech synthesizer to speak words that you want spoken."
    exit 1
fi

if [ ! -e "$(which spd-say)" ]; then
    echo "Error: This command depends on 'spd-say' command."
    pkg="speech-dispatcher"
    echo "Now searching for a '$pkg' package."
    if pm s "$pkg"; then
        echo "Run 'pm in [package-name]' to install a package."
    fi
    exit 1
fi

words="$*" # Collect all the words into a single variable.
echo "$words" # Show what is being said.
spd-say -w "$words" # Say it.
