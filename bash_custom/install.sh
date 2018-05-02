#!/usr/bin/env bash
# Install custom Bash profile stuff.

# Figure out where the script is
HERE="$(dirname "$(readlink -f "$0")")"

# Backup old dot-files and replace them with symlinks to the ones here
for file in .bash_logout .bash_profile .bashrc .logout .profile
do
    mv "$HOME/$file" "$HOME/$file.bak"
    ln -s "$HERE/$file" "$HOME/$file"
done

# Make custom bash history directory for use with the custom $PROMPT_COMMAND and hist.sh
mkdir "$HOME/.bash_history.d"
