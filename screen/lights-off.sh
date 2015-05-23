#!/bin/bash
names="
lightson.sh
lightson
"

stop() {
    # TODO: check if it's running before trying to kill it.
    echo "Stopping \"$1\" script."
    killall --user `whoami` $1
}

for name in $names
do
    stop $name
done

exit
