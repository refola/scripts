#!/bin/bash

if [ -z "$2" ]
then
	say "Usage: $(basename $0) max delta"
	say "Counts to max in increments of delta."
	exit 1
else
	max="$1"
	delta="$2"
	say "Now counting to $max in increments of $delta."
	for ((n="$delta"; n<="$max"; n+="$delta"))
	do
		say "$n"
	done
	say "That was fun."
fi
