#!/bin/bash

if volume-muted -q; then
    wasmuted=true
else
    wasmuted=false
    echo "Muting sound."
    volume-mute
fi

word="yh" # "yh" seems to be the shortest-time sound it can do
cmd=(say "$word")

if [ -e "$(which spd-say)" ]; then # use lower-level parameters to be faster
    cmd=(spd-say --wait --rate +100 "$word")
fi

echo "Using '${cmd[0]}' to start-and-stop an audio stream twice,"
echo "which seems to fix cracking audio after changing sessions."
${cmd[@]}
${cmd[@]}

if [ "$wasmuted" = "false" ]; then
    echo "Unmuting sound."
    volume-mute
fi
