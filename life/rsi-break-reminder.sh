#!/bin/sh

msg() { echo "$0: $1" | write "$USER"; }

usage="$0 minutes

Remind the user to take stretch breaks on a period of the given number
of minutes."

# main "$@"
##
# Run the script, with whichever parameters are available.
main() {
    if [ "$#" != 1 ]; then
        echo "$usage"
        exit 1
    fi
    mesg y # Enable `write` command
    while true; do
        sleep "${1}m"
        msg "Take a stretch break and fix your posture!"
    done
}

main "$@"
