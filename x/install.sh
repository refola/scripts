#!/usr/bin/env bash
## install.sh
# Install these scripts to your home directory.

# Where we are: the place that everything's relative to
here="$(dirname "$(readlink -f "$0")")"

echo "Installing Refola scripts and custom Bash environment."
for script in build_bin.sh bash_custom/install.sh; do
    script="$here/$script"
    echo "Running $script."
    "$script"
done

# TODO: Check these files before commit:

## README.md
# `echo export PATH="$PATH:~/scripts/bin" >> ~/.profile`

## bash_custom/.bashrc
# custom_sourced="$h/sampla/samselpla/scripts/sourced"
