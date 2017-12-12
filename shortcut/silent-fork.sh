#!/bin/sh
## silent-fork.sh
# Silently fork with the passed command and arguments.
"$@" 2>/dev/null >/dev/null &
