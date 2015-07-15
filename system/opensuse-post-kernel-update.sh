#!/bin/sh
# Do stuff required after kernel updates to keep the system working properly

# Fix nvidia drivers after kernel update on openSUSE
nvidia_pkgs=(
    nvidia-computeG04
    nvidia-gfxG04-kmp-desktop
    nvidia-glG04
    nvidia-uvm-gfxG04-kmp-desktop
    x11-video-nvidiaG04
)
echo "Forcing reinstallation of: ${nvidia_pkgs[*]}"
sudo zypper in --force "${nvidia_pkgs[@]}"
