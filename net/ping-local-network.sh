#!/bin/bash

doit() {
	ping -c 1 $1 | grep -B 1 "1 received" | grep -o $1
}

for ((x=1; x<255; x++));
do
	doit 192.168.0.$x &
done

sleep 4

exit

