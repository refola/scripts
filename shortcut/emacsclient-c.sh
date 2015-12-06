#!/bin/bash
# Run "emacsclient -c" ("create-frame") as a $VISUAL-compatible
# command. '-a ""' tries to start a new daemon if one isn't running.
emacsclient -c -a "" "$@"
