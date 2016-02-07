#!/bin/bash

# pm.sh - package manager frontend for multiple distros

usage="Usage: $(basename "$0") operation [packages]

pm is an interactive frontend for multiple distros' package managers,
with the goal of enabling a single set of commands to handle common
package management operations regardless of distro. It first finds the
system's package manager and then uses it to perform the given
operation.

Valid operations are as follows.

detect          Output which package manager this script detected.
help            Display this help message and exit.
in, install     Install listed package(s) and dependencies.
rm, remove      Remove listed package(s).
s, search       Search for packages.
up, upgrade     Upgrade the system.

Currently supported package managers:
* ccr (Chakra community repository tool and pacman frontend)
* pacman (package manager for Arch, Chakra, Kaos, etc)

Exit status is 0 if successful, 1 otherwise. But this should only be
used interactively, so this really really shouldn't matter.
"

# Package managers, split by frontend status
pms_frontend=(ccr)
pms_main=(pacman)
# Frontends before the main ones for fancier behavior
pms=("${pms_frontend[@]}" "${pms_main[@]}")

## Usage: bad-pm pm
# Reports to the user that the given package manager is not supported
# and exits the script.
bad-pm() {
    echo "Unsupported package manager: $1"
    exit 1
}

## Usage: pm-sudo package_manager
# Returns 0 if calls to package_manager should be prefixed with
# "sudo", otherwise returns 1.
pm-sudo() {
    if [ "$EUID" = "0" ]; then
        return 0
    else
        local front="${pms_frontend[*]}"
        local main="${pms_main[*]}"
        local test
        test="$(echo -e "$front\n$main" | grep -e "$1")"
        case "$test" in
            "$front") return 1 ;;
            "$main")  return 0 ;;
            *)        bad-pm "$1" ;;
        esac
    fi
}

## Usage: pm-run pm args
# Runs pm with args, prefixing it with sudo if needed.
pm-run() {
    local pm="$1"
    shift
    if pm-sudo "$pm"; then
        sudo "$pm" "$@"
    else
        "$pm" "$@"
    fi
}

## Usage: package_manager="$(detect)"
# Detect which package manager is being used.
detect() {
    local pm
    for pm in "${pms[@]}"; do
        if which "$pm" &> /dev/null; then
            echo -e "$pm"
            return 0
        fi
    done
    # If package manager not found, exit with error.
    bad-pm "No package manager found"
}

## Usage: install package1 [package2 [...]]
# Install listed package(s).
install() {
    echo "Upgrading system before install."
    upgrade || return 1
    local pm
    pm="$(detect)"
    local pm_args
    case "$pm" in
        ccr|pacman) pm_args=("-S" "$@") ;;
        *)          bad-pm "$pm" ;;
    esac
    echo "Installing packages."
    pm-run "$pm" "${pm_args[@]}"
}

## Usage: remove package1 [package2 [...]]
# Remove listed package(s).
remove() {
    local pm
    pm="$(detect)"
    local pm_args
    case "$pm" in
        ccr|pacman) pm="pacman" # Don't use ccr for remove.
                    pm_args=("-Rcns" "$@") ;;
        *) bad-pm "$pm" ;;
    esac
    echo "Removing packages."
    pm-run "$pm" "${pm_args[@]}"
}

## Usage: search expression [expression2 [...]]
# Search for packages with given expression.
search() {
    local pm
    pm="$(detect)"
    local pm_args
    case "$pm" in
        ccr|pacman) pm_args=("-Ss" "$@") ;;
        *) bad-pm "$pm"
    esac
    pm-run "$pm" "${pm_args[@]}"
}

## Usage: upgrade
# Upgrade the distro to the latest packages available.
upgrade() {
    local pm
    pm="$(detect)"
    local pm_check
    local pm_dl_args
    local pm_up_args
    case "$pm" in
        ccr) pm_check=mirror-check
             pm_dl_args="-Syuw"
             pm_up_args="-Su"
             ;;
        pacman) unset pm_check # no known universal "mirror-check"
                pm_dl_args="-Syuw"
                pm_up_args="-Su"
                ;;
        *) bad-pm "$pm" ;;
    esac
    if [ -n "$pm_check" ]; then
        echo "Checking mirror synchronization."
        "$pm_check" || return 1
    else
        echo "No known mirror synchronization tool for $pm. Continuing."
    fi
    echo "Downloading updates."
    pm-run "$pm" "${pm_dl_args[@]}" || return 1
    echo "Upgrading system."
    pm-run "$pm" "${pm_up_args[@]}"
}

## Usage: usage
# Show the usage message.
usage() {
    echo "$usage"
}

## Usage: main "$@"
# Do everything.
main() {
    local op="${1:-help}"
    shift
    case "$op" in
        detect)     echo "Package manager: $(detect)" ;;
        in|install) install "$@" ;;
        rm|remove)  remove "$@" ;;
        s|search)   search "$@" ;;
        up|upgrade) upgrade ;;
        help)       usage ;;
        *)          echo "Unknown operation $op."
                    usage
                    return 1 ;;
    esac
}

main "$@"
