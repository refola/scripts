#!/bin/bash
# Run "emacsclient -t" as a $EDITOR-compatible command, falling back
# to emacs-nox if needed.

# Try connecting to existing emacs daemon.
if ! (pidsof emacs && emacsclient -t "$@")
then
    # Otherwise fall back to emacs-nox.
    emacs-nox "$@"
fi
