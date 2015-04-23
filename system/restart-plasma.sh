#!/bin/sh

echo "Killing plasma."
killall plasma-desktop

echo "Starting plasma again."
plasma-desktop &
