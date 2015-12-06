#!/bin/bash
# Run "emacsclient -t" (terminal mode) as a $EDITOR-compatible
# command. '-a ""' tries to start a new daemon if one isn't running.
emacsclient -t -a "" "$@"
