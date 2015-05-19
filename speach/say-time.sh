#!/bin/sh
DD="[0-9][0-9]"
say the time is `uptime | grep -o $DD:$DD:$DD | grep -o $DD:$DD`.
