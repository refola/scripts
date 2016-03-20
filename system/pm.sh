#!/bin/bash

# pm.sh - package manager frontend for multiple distros

usage="Usage: $(basename "$0") [operation] [packages]

pm is an interactive frontend for multiple distros' package managers,
with the goal of enabling a single set of commands to handle common
package management operations regardless of distro. It first finds the
system's package manager and then uses it to perform the given
operation.

Valid operations are as follows.

det, detect     Output which package manager this script detected.
h, help         Display this help message and exit.
if, info        Display information about listed package(s).
in, install     Install listed package(s) and dependencies.
rm, remove      Remove listed package(s).
s, search       Search for packages.
up, upgrade     Upgrade the system.

Currently supported package managers:
* apt-get (Debian, *buntu, Mint, etc)
* ccr (Chakra)
* pacman (Arch, Chakra, Kaos, etc)
* zypper (openSUSE)

Functions implemented:
pkg mgr   if   in   rm    s   up
apt-get  yes  yes  yes  yes  yes
ccr      yes  yes  yes  yes  yes
pacman   yes  yes  yes  yes  yes
zypper    no  yes  yes  yes  yes

Exit status is 0 if successful, 1 otherwise. But this script should
only be used interactively, so exit status really shouldn't matter.
"

# Package managers, split by frontend status
pms_frontend=(ccr)
pms_main=(apt-get pacman zypper)
# Frontends before the main ones for fancier behavior
pms=("${pms_frontend[@]}" "${pms_main[@]}")

## Usage: bad-pm pm
# Reports to the user that the given package manager is not supported
# and exits the script.
bad-pm() {
    err "Unsupported package manager: \e[1m$1\e[0m"
    exit 1
}

## Usage: err args ...
# Echos args to stderr, prefixed with "Error: "
err() {
    echo -e "\e[1;4;91mError\e[0m: $1" 1>&2
}

## Usage: msg args ...
# Echos args in fancy style, so it's clear that it's from pm.
msg() {
    echo -e "\e[1;34mpm: \e[0;32m$1\e[0m"
}

## Usage: my_text="$(bold args ...)"
# Returns given text, formatted so 'echo -e' prints it bolded.
bold() {
    echo -n "\e[0;1m$*\e[0m"
}

## Usage: maybe-sudo command
# Returns 0 if calls to command should be prefixed with "sudo",
# otherwise returns 1.
pm-sudo() {
    if [ "$EUID" = "0" ]; then
        return 0
    else
        local front="${pms_frontend[*]}"
        local main="${pms_main[*]}"
        local test
        test="$(echo -e "$front\n$main" | grep -e "\b$1\b")"
        case "$test" in
            "$front")
                return 1 ;;
            "$main")
                return 0 ;;
            *) # Blindly assume that unknown commands don't need sudo.
                return 1 ;;
        esac
    fi
}

## Usage: cmd args ...
# Runs command cmd with given args, first telling the user what
# command is being ran.
cmd() {
    msg "Running $(bold "'$*'")"
    "$@"
}

## Usage: pm-run pm args ...
# Runs pm with args, prefixing it with sudo if needed.
pm-run() {
    local pm="$1"
    shift
    if pm-sudo "$pm"; then
        cmd sudo "$pm" "$@"
    else
        cmd "$pm" "$@"
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

## Usage: pm-try-run-one "cmd with args ..."
# Tries to run a single command, with sudo as applicable, and with
# arguments as applicable, returning 1 on failure.
pm-try-run-one() {
    local IFS=' ' # Split on spaces ...
    ## ... and let set have the intended space-separated args
    ## contained in $1 without shellcheck complaining.
    # shellcheck disable=SC2086
    set $1
    local cmd="$1"
    shift
    local args=("$@")
    pm-run "$cmd" "${args[@]}"
}

## Usage: pm-try-run "cmd1 with args ..." [...]
# Tries to run each command, with sudo as applicable, and with
# arguments as applicable, returning 1 on failure.
pm-try-run() {
    for cmd in "$@"; do
        pm-try-run-one "$cmd" || return 1
    done
}

## Usage: info package ...
# List information about given package(s).
info() {
    local pm
    pm="$(detect)" || return 1
    msg "Listing package info."
    case "$pm" in
        apt-get)
            pm-try-run "apt-cache --no-all-versions show $*" ;;
        ccr|pacman)
            pm-try-run "pacman -Qi $*" ;;
        *)
            bad-pm "$pm" ;;
    esac
}

## Usage: install package1 [package2 [...]]
# Install listed package(s).
install() {
    msg "Upgrading system before install."
    upgrade || return 1
    local pm
    pm="$(detect)" || return 1
    msg "Installing packages."
    case "$pm" in
        apt-get)
            pm-try-run "$pm install $*" ;;
        ccr|pacman)
            pm-try-run "$pm -S $*" ;;
        zypper)
            pm-try-run "$pm in $*" ;;
        *)
            bad-pm "$pm" ;;
    esac
}

## Usage: remove package1 [package2 [...]]
# Remove listed package(s).
remove() {
    local pm
    pm="$(detect)" || return 1
    msg "Removing packages."
    case "$pm" in
        apt-get)
            pm-try-run "$pm autoremove $*" ;;
        ccr|pacman)
            pm-try-run "pacman -Rcns $*" ;;
        zypper)
            pm-try-run "$pm rm -u $*" ;;
        *)
            bad-pm "$pm" ;;
    esac
}

## Usage: search expression [expression2 [...]]
# Search for packages with given expression.
search() {
    local pm
    pm="$(detect)" || return 1
    case "$pm" in
        apt-get)
            pm-try-run "apt-cache search $*" ;;
        ccr|pacman)
            pm-try-run "$pm -Ss $*" ;;
        zypper)
            pm-try-run "$pm se $*" ;;
        *)
            bad-pm "$pm" ;;
    esac
}

## Usage: upgrade
# Upgrade the distro to the latest packages available.
upgrade() {
    local pm
    pm="$(detect)" || return 1
    msg "Running all commands to properly upgrade the system."
    case "$pm" in
        apt-get)
            pm-try-run "$pm update"\
                       "$pm upgrade -d"\
                       "$pm upgrade" ;;
        ccr)
            pm-try-run "mirror-check"\
                       "pacman -Syuw"\
                       "pacman -Su"\
                       "ccr -Syu --ccronly" ;;
        pacman)
            pm-try-run "$pm -Sy"\
                       "$pm -Suw"\
                       "$pm -Su" ;;
        zypper)
            pm-try-run "$pm ref"\
                       "$pm up -d"\
                       "$pm up" ;;
        *)
            bad-pm "$pm" ;;
    esac
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
        det|detect)
            local manager
            manager="$(detect)" || exit 1
            msg "Package manager: $(bold "$manager")" ;;
        'if'|info)
            info "$@" ;;
        'in'|install)
            install "$@" ;;
        'rm'|remove)
            remove "$@" ;;
        s|search)
            search "$@" ;;
        up|upgrade)
            upgrade ;;
        h|'help')
            usage ;;
        *)
            err "Unknown operation: $op"
            usage
            exit 1 ;;
    esac
}

main "$@"
