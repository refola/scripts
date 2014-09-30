#!/bin/bash
echo "Running script for checking file existence."
if [ -z "$1" ]
then
	echo "Usage: `basename $0` filename"
	echo "This checks if filename exists and says what it is."
	exit
fi

checktype() {
	if [ -f "$1" ]
	then
		echo "It's a file! Checking type...."
		file "$1"
	elif [ -d "$1" ]
	then
		echo "It's a directory! Listing contents...."
		ls -A "$1"
	elif [ -h "$1" ]
	then
		echo "It's a symbolic link! Here's where it points...."
		basename "$1"
	elif [ -b "$1" ]
	then
		echo "It's a block device! You might be able to (carefully!) do something to it with \"dd\"...."
	else
		echo "It's something else. Try asking the Internet or something for more sophisticated identification...."
	fi
}

if [ -e "$1" ]
then
	echo "It exists! Now checking type...."
	checktype "$1"
else
	echo "404: File not found."
fi

exit
