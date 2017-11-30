#!/bin/bash
usage="smooth-volume-up [delay [increment]]

Gradually increase volume every delay (default: 2s) interval, with an
increment% (default 5) increase each time."

[ -z "$2" ] && echo "$usage"

delay="${1-2s}"
inc="${2-5}"
count=$((100/inc + 1))
for ((x=1; x<="$count"; x++)); do
    echo "$x/$count"
    volume-up "$inc" > /dev/null
    sleep "$delay"
done
