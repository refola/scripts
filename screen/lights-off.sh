#!/bin/bash
names="
lights-on.sh
lights-on
"

stop() {
    # TODO: check if it's running before trying to kill it.
    echo "Stopping \"$1\" script."
    killall --user "$USER" "$1"
}

for name in $names
do
    stop "$name"
done

exit
