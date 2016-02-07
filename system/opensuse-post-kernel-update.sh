#!/bin/sh
# Do stuff required after kernel updates to keep the system working properly

echo "This script might not be necessary since openSUSE 42.1 Leap."

# Fix nvidia drivers after kernel update on openSUSE
nvidia_pkgs=(
    nvidia-computeG04
    nvidia-gfxG04-kmp-default
    nvidia-glG04
    nvidia-uvm-gfxG04-kmp-default
    x11-video-nvidiaG04
)
echo "Forcing reinstallation of: ${nvidia_pkgs[*]}"
sudo zypper in --force "${nvidia_pkgs[@]}"
