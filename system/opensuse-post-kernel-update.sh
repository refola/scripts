#!/bin/sh
# Do stuff required after kernel updates to keep the system working properly

# Fix nvidia drivers after kernel update on openSUSE
sudo zypper in --force nvidia-glG03 nvidia-computeG03 nvidia-gfxG03-kmp-desktop nvidia-uvm-gfxG03-kmp-desktop x11-video-nvidiaG03

