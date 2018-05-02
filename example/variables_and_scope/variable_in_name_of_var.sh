#!/usr/bin/env bash

VAR_X="after W"
VAR_Y="before Z"

LETTER="X"

# I want to be able to use a variable's contents as part of a variable's name, e.g., like this...
echo "$LETTER is ${VAR_$LETTER}."
# ... but Bash gives me a "bad substitution" error.
