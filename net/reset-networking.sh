#!/usr/bin/env bash

### Space-separated lists of interfaces and modules to reset.
INTERFACES="enp3s0 fake_interface_name_for_testing"
MODULES="r8169 fake_module_name_for_testing"

### One-liners that enable and disable modules and interfaces.
disable_module() { sudo modprobe -r "$1"; }
disable_interface() { sudo ifconfig "$1" down; }
enable_module() { sudo modprobe "$1"; }
enable_interface() { sudo ifconfig "$1" up; }

### One-liners that filter modules and interfaces to only those found.
filter_module() { begins_line "$1" lsmod; }
filter_interface() { begins_line "$1" ifconfig; }

## Usage: begins_line text command
# Outputs text iff it begins a line in command's output.
begins_line() {
    if $2 | egrep -q "^$1"
    then echo "$1"
    fi
}

## Usage: loop_cmd list command
# Runs command for each item in quoted list.
loop_cmd() {
    local items="$1"
    local cmd="$2"
    for item in $items
    do $cmd "$item"
    done
}

## Usage: main
# Resets networking interfaces and modules, hopefully fixing whatever
# networking issues may be present.
main() {
    local modules="$(loop_cmd "$MODULES" filter_module)"
    local interfaces="$(loop_cmd "$INTERFACES" filter_module)"
    echo "Disabling and re-enabling networking. Note: This uses sudo."
    echo "Bringing down interface(s): $interfaces"
    loop_cmd "$interfaces" disable_interface
    echo "Unloading module(s): $modules"
    loop_cmd "$modules" disable_module
    echo "Reloading module(s): $modules"
    loop_cmd "$modules" enable_module
    SEC=3
    echo "Waiting $SEC seconds for modules to finish loading."
    sleep "$SEC"
    echo "Bringing up interface(s): $interfaces"
    loop_cmd "$interfaces" enable_interface
}

main
