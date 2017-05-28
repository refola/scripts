#!/bin/bash
echo "Running smooth volume-increasing script."

SEC="9"

if [ -z "$1" ]
then
    echo "You can pass this how many seconds to wait between increments."
else
    SEC="$1"
fi

for ((x=1; x<=20; x++));
do
    echo $x/20
    volume-up > /dev/null
    sleep "$SEC"
done

exit
