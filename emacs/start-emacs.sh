#!/usr/bin/env bash
## start-emacs.sh

start_dir="/home/$USER"
if [ ! -d "$start_dir" ] || [ -z "$USER" ]; then
    start_dir="$HOME"
fi

cmd=(emacs --daemon --chdir "$start_dir")

# If the current user isn't running Emacs, then start a new daemon.
if ! pgrep --euid "$EUID" --full "${cmd[*]}" >/dev/null; then
    "${cmd[@]}"
fi
