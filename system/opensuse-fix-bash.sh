#!/bin/sh
# Do stuff required after updates that make Bash spit out garbage.

for file in grub libreoffice.sh ooffice.sh
do
    target="/etc/bash_completion.d/$file"
    if [ -f  "$target" ]
    then
        echo "Removing $target."
        sudo rm "$target"
    fi
    # TODO: Wait for an update to Grub or LibreOffice and see if this
    # has kept Bash from breaking.
    echo "Making blank file at $target."
    sudo touch "$target"
done
