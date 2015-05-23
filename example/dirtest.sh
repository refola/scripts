#!/bin/bash
echo "Running \"Directory test\" script to benchmark directory creation."

place="./directorybenchmarktest"
mkdir $place
cur=$place

makedirs() {
    echo "Making directory tree $1 levels deep."
    for ((num=0; num<$1; num++));
    do
	cur="$cur/$num"
	mkdir $cur
    done
}

echo "Timing directory creation 1000 levels deep."
time makedirs 1000

echo "Deleting test directories."
time rm -r $place

exit
