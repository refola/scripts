#!/usr/bin/env bash
# lights-on.sh
# Keep the screensaver from running.

USAGE="lights-on [-q]

Repeatedly run a command to keep the screensaver from running.

Skip this usage text with '-q'.

Compatibility: This _should_ work anywhere the 'xdg-screensaver'
command exists. In particular, this is likely to work under modern
Linux and BSD distros and any system that follows freedesktop.org
standards. There's a slim chance this includes MacOS, and a near-nil
chance that this includes Windows.

Please run 'lights-off' to stop."

ERR_LOCK="Error: lock already exists.

Another instance of this script may already be running. If so, then
'lights-off' will stop it.

If you're sure that this script isn't running (e.g., if it wasn't
killed with 'lights-off' before the last shutdown), then you can
manually clear the lock with these commands.

    pidlock remove-pids lights-on all
    pidlock unlock lights-on

If you're unsure, then please check the process(es) with PIDs
corresponding to the files in this path.

    $(pidlock path lights-on)
"

# Acquire lock or exit with message explaining failure.
if ! pidlock lock lights-on; then
    echo "$ERR_LOCK"
    exit 1
fi

# Show usage if by default.
if [ "$1" != "-q" ]; then
    echo "$USAGE"
fi

# Start screensaver-preventing loop in background.
while true; do
    xdg-screensaver reset
    sleep 50
done &
# Immediately add loop's PID to lock.
pidlock addpids lights-on "$!"
