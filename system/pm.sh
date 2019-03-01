#!/usr/bin/env bash

# pm.sh - package manager frontend for multiple distros

# Package managers, split by sudo-using status
NON_SUDO_PMS=($(get-data "pm/non-sudo-pms")) ||
    fatal "Could not get list of non-sudo package managers."
SUDO_PMS=($(get-data "pm/sudo-pms")) ||
    fatal "Could not get list of sudo-using package managers."

# Non-sudo pms first to minimize directly calling sudo.
PMS=("${NON_SUDO_PMS[@]}" "${SUDO_PMS[@]}")

# Is debug mode enabled?
DEBUG=

# Is a particular package manager manually selected?
PM=

# Instructions
USAGE="Usage: $(basename "$0") [options ...] [operation [package ...]]

pm is an interactive frontend for multiple distros' package managers,
with the goal of enabling a single set of commands to handle common
package management operations regardless of distro. It first finds the
system's package manager and then uses it to perform the given
operation.

Valid operations are as follows.

det, detect     Output which package manager this script detected.
h,   help       Display this help message and exit.
if,  info       Display information about listed package(s).
in,  install    Install listed package(s) and dependencies.
rm,  remove     Remove listed package(s).
s,   search     Search for packages.
up,  upgrade    Upgrade the system.

Current options are as follows.

dbg, debug      Skip running package manager commands.
pm=manager      Force use of given package manager.

Currently supported package managers:
* apt-get (Debian, *buntu, Mint, etc)
* chaser (Chakra)
* nix-env (NixOS)
* pacman (Arch, Chakra, Kaos, etc)
* zypper (openSUSE)

Limitations:
* The info command doesn't yet support zypper.
* This works by checking for the existence of a package manager, but
  it should check 'ID=' and 'ID_LIKE' in /etc/os-release instead.

Developer information:
* Please see $(get-data pm/README.md -path) for how package manager
  operations are defined.
"


## Usage: package_manager="$(detect)"
# Detect which package manager is being used.
detect() {
    if [ -n "$PM" ]; then
        echo "$PM"
        return 0
    fi
    local pm
    for pm in "${PMS[@]}"; do
        if which "$pm" &> /dev/null; then
            echo -e "$pm"
            return 0
        fi
    done
    # If package manager not found, exit with error.
    fatal "No package manager found"
}

## Usage: fatal args ...
# Runs err with given args and exits the script.
fatal() {
    echo -e "\e[1;4;91mError\e[0m: $*" 1>&2
    exit 1
}

## Usage: maybe-sudo command operation
# Returns 0 if calls to command in operation should be prefixed with
# "sudo", otherwise returns 1.
maybe-sudo() {
    local cmd="$1"
    local op="$2"
    local old_IFS="$IFS"
    local IFS=" "
    local zero="${SUDO_PMS[*]}"
    local one="${NON_SUDO_PMS[*]}"
    IFS="$old_IFS"
    local test
    test="$(echo -e "$zero\n$one" | grep -e "\b$cmd\b")"
    case "$test" in
        "$zero")
            if ! [ -f "$(get-data "pm/$op/.no-sudo" -path)" ]; then
                return 0
            else
                return 1
            fi
            ;;
        "$one")
            return 1 ;;
        *) # Blindly assume that unknown commands don't need sudo.
            return 1 ;;
    esac
}

## Usage: msg args ...
# Echos args in fancy style, so it's clear that it's from pm.
msg() {
    echo -e "\e[1;34mpm: \e[0;32m$1\e[0m"
}

## Usage: pm-op operation [args ...]
# Get and run the appropriate commands for the system's package
# manager to do the requested operation with the given arguments.
pm-op() {
    local pm
    pm="$(detect)" || return 1
    local op="$1"
    shift
    local args="$*"
    local raw_cmds
    raw_cmds="$(get-data "pm/$op/$pm")" ||
        fatal "Can't $op with $pm."
    local IFS=$'\n'
    for line in $raw_cmds; do
        cmd="${line/ *}"
        if maybe-sudo "$cmd" "$op"; then
            line="sudo $line"
        fi
        line="$(echo "$line" | sed -r "s/\\\$args/$args/g")" ||
            fatal "Failed \$args substitution: $line"
        msg "Running $line"
        if [ -z "$DEBUG" ]; then
            eval "$line" || fatal "Command did not complete successfully."
        fi
    done
}


## Usage: main "$@"
# Do everything.
main() {
    if [ -z "$1" ]; then
        echo "$USAGE"
        exit 1
    fi
    local arg="$1"
    shift
    case "$arg" in
        dbg|debug)
            DEBUG=true
            msg "Debug mode enabled. Commands won't be ran."
            main "$@" ;;
        det|detect)
            local manager
            manager="$(detect)" || exit 1
            msg "Package manager: $manager" ;;
        h|'help')
            echo "$USAGE" ;;
        'in'|install)
            msg "Upgrading system before install."
            pm-op up
            pm-op 'in' "$@" ;;
        pm=*)
            PM="${arg/pm=/}"
            msg "Forcing use of package manager $PM."
            main "$@" ;;
        *)
            # Most commands don't need anything special. Just gotta
            # check that they exist.
            if [ -d "$(get-data "pm/$arg" -path)" ]; then
                pm-op "$arg" "$@"
            else
                msg "Unknown argument: $arg"
                echo "$USAGE"
                exit 1
            fi ;;
    esac
}

main "$@"
