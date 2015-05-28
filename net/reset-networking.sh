#!/bin/bash

# Hardcoded; change on different systems or as-needed.
IF="enp3s0"

# Get the interface info, limit to the line with the driver's name, and remove the 8 characters "driver: ", finally resulting in just the driver's name.
# NOTE: This probably won't work for non-ethernet interfaces like wifi.
DRIVER="$(ethtool -i $IF | grep driver | cut -c 9-)"

echo "Resetting networking for interface $IF."
echo "Here are its current stats, in case you're interested."
ifconfig "$IF"

echo "Bringing down interface $IF (requires password for sudo)."
sudo ifconfig "$IF" down

echo "Removing driver $DRIVER."
sudo modprobe -r "$DRIVER"

echo "Reloading driver $DRIVER."
sudo modprobe "$DRIVER"

SEC=3
echo "Waiting $SEC seconds for stuff to activate...."
sleep "$SEC"

echo "Bringing up interface $IF."
sudo ifconfig "$IF" up

echo "Done! Enjoy the zeroed stats, as follows."
ifconfig "$IF"

exit
