#!/bin/bash
echo "Removing everything from system cache."

echo "Running \"sync\" to flush buffers first."
sync

echo "Running \"echo 3 | sudo tee /proc/sys/vm/drop_caches\" to drop all caches."
echo 3 | sudo tee /proc/sys/vm/drop_caches

exit
