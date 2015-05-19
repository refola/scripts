#!/bin/bash

if [ -z "$2" ]
then
	say "`basename $0` max delta"
	sleep 3 # Since "say" will fight with itself....
	say "Counts to max in increments of delta."
	exit 1
else
	max=$1
	delta=$2

	say "Now counting to $max in increments of $delta."
        sleep 3.5 # Since "say" will fight with itself....

	for ((n=$delta; n<=$max; n+=$delta));
	do
		say "$n"
		sleep 1 # Since "say" will fight with itself....
	done

	say "That was fun."
fi

exit
