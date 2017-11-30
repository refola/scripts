#!/bin/bash

## Usage: run-maybe-5 program args ...
# Runs program5 if it exists, or program if program5 doesn't exist,
# passing along given args.
run-maybe-5() {
    local prog="$1"
    shift
    if which "${prog}5" &>/dev/null; then
        prog="${prog}5"
    fi
    $prog "$@"
}

## Usage: restart app [start-args ...]
# Uses kquitapp(5) and kstart(5) to stop and start the given app,
# using the given args on start.
restart() {
    echo "Restarting $1."
    run-maybe-5 kquitapp "$1"
    sleep 1
    run-maybe-5 kstart "$@" &
    sleep 1
}

echo "Restarting 'KDE5' desktop stuff."
restart kwin_x11 --replace
restart plasmashell
echo "Done."
