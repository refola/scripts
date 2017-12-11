#!/bin/bash
## start-emacs.sh

cmd=(emacs --daemon --chdir "$H")

# If not (Emacs is running), then start a new daemon.
if ! pgrep -u "$USER" -f "${cmd[*]}" >/dev/null; then
    "${cmd[@]}"
fi
