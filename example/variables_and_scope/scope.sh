#!/bin/bash

func1() {
	func2
}

func2() {
	echo $var
}

# Would echo a blank line, since $var isn't defined yet.
#func1

# This works!
var="This should be called by a function defined earlier. That function should be called by another function defined even earlier."
func1

exit
