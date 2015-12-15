#!/bin/sh
# Do stuff required after updates that make Bash spit out garbage.

for file in grub libreoffice.sh ooffice.sh
do
    to_delete="/etc/bash_completion.d/$file"
    echo "Removing $to_delete"
    sudo rm "$to_delete"
done
