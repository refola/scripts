#!/bin/bash
echo "Running smooth volume-increasing script"
for ((x=1; x<20; x++));
do
    echo $x/20
    volume-up > /dev/null
    sleep 9
done
exit
