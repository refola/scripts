#!/bin/bash

if [ -z "$1" ]
then
    echo "Usage: $(basename "$0") mount-point"
    echo "Sets things up, chroots into mount-point, and tares things down when done."
    exit 1
fi

echo "Setting up chroot for $1."
cd "$1"
sudo mount -o bind /dev dev
sudo mount -o bind /proc proc
sudo mount -o bind /sys sys
sudo mount -t tmpfs tmpfs tmp

echo "Chrooting into $1."
sudo chroot "$1"

echo "Undoing special mounts in $1."
sudo umount dev proc sys tmp
