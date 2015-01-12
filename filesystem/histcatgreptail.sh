#!/bin/bash
# Searches through custom Bash history folder for commands matching given pattern, displaying last several.

DIR="$HOME/.bash.d/history"

COUNT="$2"
if [ -z "$2" ]
then
	COUNT="50"
fi

if [ -z "$1" ]
then
	echo "Usage: `basename $0` pattern [count]"
	echo "Searches files in $DIR for pattern, returning the last count (default $COUNT) lines"
	exit 1
fi

cd "$DIR"
cat `ls $DIR` | egrep "$1" | tail -n $COUNT

exit 0
