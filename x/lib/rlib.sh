#!/bin/sh
##rlib.sh
# Refola library of shell functions for convenience and consistency.

USAGE=". \$($0 . [library [...]])
$0 [library [...]]

First invocation: Source this script and any other library scripts
listed.

Second invocation: Show provided function/variable documentation for
this script and any other library scripts listed.

Shell compatibility: This is currently developed and tested on
Bash. It would be cool to make it near-POSIX-compatible with this
being 'sh'-compatible and using automatic shell detection and
as-needed sourcing of shell-specific files, but that seems
complicated.

Code style forcing: Please load libraries before defining anything
with your own code. Otherwise conflicts may overwrite your functions
and variables."

# doc library[/function] [...]
## Shows documentation comments for "function" (or all functions if
## unspecified) found in "library".
doc() {
    local lib func
    while [ -n "$1" ]; do
        lib="${1%/*}"
        func="${1#*/}"
        
