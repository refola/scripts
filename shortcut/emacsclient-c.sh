#!/bin/bash
# Run "emacsclient -c" as a $VISUAL-compatible command, falling back
# to emacs-nox if needed.

# Try connecting to existing emacs daemon.
## Note: Redirecting emacsclient's output keeps it from getting the
## terminal's name, so only suppress pidsof's output.
if ! (pidsof emacs &> /dev/null && emacsclient -c "$@")
then
    # Otherwise fall back to emacs.
    echo "Could not connect to emacs daemon. Trying to start new instance."
    if emacs --daemon
    then
	echo "Emacs daemon started. Now trying to connect."
	if ! emacsclient -c "$@"
	then
	    echo "Could not connect to freshly started emacs daemon."
	    echo "Something's seriously wrong. Giving up."
	fi
    else
	echo "Could not start emacs in daemon mode. Starting it in slow mode."
	emacs "$@"
	echo "Try running 'emacs --daemon' for faster startup."
    fi
fi
