#!/usr/bin/env bash

if [ -z "$1" ]
then
    echo "Usage: $(basename "$0") mount-point"
    echo "Sets things up, chroots into mount-point, and tears things down when done."
    exit 1
fi

ch="$1"
echo "Setting up chroot for $ch."
cd "$ch"

binds=( dev home proc run sys )
for bind in "${binds[@]}"; do
    echo "Binding $bind to $ch/$bind."
    sudo mount -o bind "/$bind" "$ch/$bind"
done

sudo mount -t tmpfs tmpfs tmp

echo "Chrooting into $ch."
sudo chroot "$ch"

echo "Undoing special mounts in $ch."
sudo umount "${binds[@]}" tmp
