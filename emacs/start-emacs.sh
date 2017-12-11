#!/bin/bash
## start-emacs.sh

cmd=(emacs --daemon --chdir "/home/$USER")

# If the current user isn't running Emacs, then start a new daemon.
if ! pgrep -u "$USER" -f "${cmd[*]}" >/dev/null; then
    "${cmd[@]}"
fi
