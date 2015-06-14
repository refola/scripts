#!/bin/bash
# Run "emacsclient -c" as a $VISUAL-compatible command, falling back
# to emacs-nox if needed.

# Try connecting to existing emacs daemon.
## Note: Redirecting emacsclient's output keeps it from getting the
## terminal's name, so only suppress pidsof's output.
if ! (pidsof emacs &> /dev/null && emacsclient -c "$@")
then
    # Otherwise fall back to emacs.
    emacs "$@"
fi
