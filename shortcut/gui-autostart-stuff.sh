#!/bin/sh

echo "This script is intended to auto-launch a bunch of programs that
are wanted for a GUI computing session. If you are seeing this
message, then you're doing it wrong. See your desktop environment's
documentation for how to do it right."

commands=(
    #"godoc -http=:6060" # Go language documentation server
    "redshift-control -" # Start Redshift with saved settings
    #"cache-places" # Pre-cache a bunch of common stuff
    "emacs --daemon" # Enable emacsclient for instantness
)

for cmd in "${commands[@]}"
do
    $cmd
done
