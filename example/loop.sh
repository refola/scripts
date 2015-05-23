#!/bin/bash
echo "loop \$1 script"
times=$1
if [ -z "$1" ] ; then
    times=5
fi
for ((x=0; x<$times; x++));
do
    echo "x=$x"
done
exit
