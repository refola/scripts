#!/bin/bash

if [ -z "$1" ]
then
    echo "Usage: $(basename "$0") words that you want spoken"
    echo "Uses a speech synthesizer to speak words that you want spoken."
    echo
    echo "Note: This depends on the 'spd-say' command. In Chakra Linux,"
    echo "this command is found in the 'speech-dispatcher' package."
    exit 1
fi

words="$(echo "$@")" # Collect all the words into a single variable.
echo $words # Show what is being said.
spd-say -w "$words" # Say it.
