#!/bin/bash
# tuple_funcs.sh

# Demonstrates how to do stuff with tuples and functions in Bash as
# part of a quest to eventually understand how well Bash implements
# the programming revelations of 1958.

NUMBERS="
# jbobau español English
0 no cero zero
1 pa uno one
2 re dos two
3 ci tres three
4 vo quatro four
5 mu cinco five
6 xa seis six
7 ze siete seven
8 bi ocho eight
9 so nueve nine
10 pano diez ten
11 papa once eleven
20 reno veinte twenty
"

# Usage: column matrix n
# Prints the nth column/entry of each tuple/row in a matrix.
column() {
	local TUPLES="$1"
	local N="$2"
	local IFS=$'\n' # We're interested in the newline-separated tuples here.
	for TUPLE in $TUPLES
	do
		local IFS=" " # Now we want space-separated items.
		set $TUPLE
		echo -n "${!N} "
	done
	echo
}

# Usage: transpose matrix ncolumns
# Prints the transpose of the given tuples, i.e., swapping between
# rows and columns.
transpose() {
	local MATRIX="$1"
	local N="$2"
	local IFS=$'\n'
	for n in $(seq $N)
	do
		column "$MATRIX" "$n"
	done
}

# Usage: head list
# Prints first item/row of list/matrix.
head() {
	local IFS=$'\n'
	set $1
	echo "$1"
}

# Usage: tail list
# Prints all but the first item/row of list/matrix.
tail() {
	local IFS=$'\n'
	set $1
	shift
	for i in $*
	do
		echo "$i"
	done
}

SNAKE="
head 0
tail 1
tail 2
tail 3
"
echo "Snake's head: $(head "$SNAKE")"
echo "Snake's tail: $(tail "$SNAKE")"

i=0
for LANG in $(head "$NUMBERS")
do
	i=$(expr $i + 1)
	echo -e "\n$i: $LANG"
	column $(tail "$NUMBERS") $i
done

echo -e "\nHere are the numbers transposed."
transpose "$NUMBERS" 4
