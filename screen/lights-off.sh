#!/usr/bin/env bash
# lights-off.sh
# Kill running lights-on script so the screensaver can run again.

pidlock kill lights-on
code=$?
if [[ "$code" != "0" ]]; then
    echo "Could not stop lights-on. Maybe it's not running?"
    echo "(pidlock status code $code)"
fi
exit $code
