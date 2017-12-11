#!/bin/bash
## emacsclient-*.sh
# Run `emacsclient -*` as an environment variable-compatible command.
# command. Note that `*` can currently only be `c` or `t`; see the
# switch in the code.

start-emacs # Make sure the daemon is started.

switch="${0/*\/emacsclient-/}"
case "$switch" in
    c|t) # c: ("create-frame") for $VISUAL
        # t: ("terminal" mode) for $EDITOR
        emacsclient "-$switch" "$@"
        ;;
    *) # What is this?
        echo "Error: Unknown switch '$switch'" >&2
        exit 1
        ;;
esac
