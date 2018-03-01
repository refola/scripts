#!/bin/bash
## start-emacs.sh

cmd=(emacs --daemon --chdir "${H-$HOME}")

# If the current user isn't running Emacs, then start a new daemon.
if ! pgrep --euid "$EUID" --full "${cmd[*]}" >/dev/null; then
    "${cmd[@]}"
fi
