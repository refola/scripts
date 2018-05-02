#!/usr/bin/env bash
# Assuming SimCity 4 has been installed, this runs it with the parameters found most useful, as explained below.
# "-w": windowed; doesn't work; use desktop emulation in Wine.
# "-CPUCount:2": keep the weird built-in scheduler from fucking up on multicore systems; try other values if needed.
# On my earlier Core 2 Due system with 2 cores and hyperthreading, 1 worked.
# On my current Phenem II X6 system with 6 cores and no hyperthreading, 2 seems to work.
# "-Intro:off": skip the intro video to save loading time.
# "-CustomResultion:enabled": allow resolutions not envisioned at the time.
# "-r:1920x1080x32": 1920 horizontal resolution, 1080 vertical resolution, and 32-bit color depth.

CMD="simcity4"
PARAMS="-CPUCount:2 -Intro:off -CustomResolution:enabled -r:1920x1080x32"

echo "Starting SimCity4 via \"$CMD $PARAMS\"."
$CMD $PARAMS
