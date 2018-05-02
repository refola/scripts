#!/usr/bin/env bash
# Example script to run "go get" and "go build" for the given go-gettable project, keeping it local to wherever this script is located.
# Simply edit PKG, post this script somewhere, and tell your project's users to do the following:
# 1. Install Go (see https://golang.org/doc/install).
# 2. Place this script where you want the program to be.
# 3. Make this script executable and run it.

# License: public domain/Unlicense (unlicense.org)
# Author: Mark Haferkamp (mark åt refola.com)

PKG="$1" # Change this to your project's go-gettable location that produces a runnable binary when go-built
#PKG="github.com/refola/tacs/cmd"  # example

# Be here now.
DELINKED=`readlink -f "$0"`
HERE="`dirname "$DELINKED"`"
cd "$HERE"

GOPATH="$HERE"
go get "$PKG"
go build "$PKG"
