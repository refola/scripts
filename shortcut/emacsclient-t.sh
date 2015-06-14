#!/bin/bash
# Run "emacsclient -t" as a $EDITOR-compatible command, falling back
# to emacs-nox if needed.

# Try connecting to existing emacs daemon.
## Note: Redirecting emacsclient's output keeps it from getting the
## terminal's name, so only suppress pidsof's output.
if ! (pidsof emacs &> /dev/null && emacsclient -t "$@")
then
    # Otherwise fall back to emacs-nox.
    echo "Could not connect to emacs daemon. Starting new instance."
    emacs-nox "$@"
    echo "Try running 'emacs --daemon' for faster startup."
fi
