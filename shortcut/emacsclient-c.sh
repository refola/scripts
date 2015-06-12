#!/bin/bash
# Run "emacsclient -c" as a $VISUAL-compatible command, falling back
# to emacs-nox if needed.

# Try connecting to existing emacs daemon.
if ! (pidsof emacs && emacsclient -c "$@") 2> /dev/null
then
    # Otherwise fall back to emacs.
    emacs "$@"
fi
