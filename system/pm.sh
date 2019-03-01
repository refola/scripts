#!/usr/bin/env bash

# pm.sh - package manager frontend for multiple distros

# Package managers, split by sudo-using status
PMS=($(get-data "pm/pms")) ||
    fatal "Could not get list of supported package managers."

# Is debug mode enabled?
DEBUG=

# Is a particular package manager manually selected?
PM=

# Instructions
USAGE="Usage: pm [options ...] [operation [package ...]]

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
* ccr, chaser (Chakra)
* dnf (Fedora)
* nix-env (NixOS)
* pacman (Arch, Chakra, Kaos, etc)
* zypper (openSUSE)

Limitations:
* dnf: info and search commands not supported
* zypper: info command not supported
* All: package managers should be inferred from 'ID=' and 'ID_LIKE' in
  /etc/os-release instead of checking mere command existance.

Developer information:
* Please see $(get-data pm/README.md -path) for how package manager
  operations are defined.
"


## Usage: cmd command [args ...]
# Echo and then run given command with given args, failing on error.
cmd() {
    msg "Running command: $*"
    command "$@" ||
        fail "Unsuccessful command: $*"
}
## Usage: scmd command [args ...]
# Shortcut for: cmd sudo command [args ...]
scmd() { cmd sudo "$@"; }

## Usage: fail args ...
# Runs err with given args and exits the script.
fail() {
    echo -e "\e[1;4;91mError\e[0m: $*" 1>&2
    exit 1
}

## Usage: msg args ...
# Echos args in fancy style, so it's clear that it's from pm and not
# underlying package manager commands.
msg() {
    echo -e "\e[1;34mpm: \e[0;32m$1\e[0m"
}


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

## Usage: pm-op operation [args ...]
# Get and run the appropriate commands for the system's package
# manager to do the requested operation with the given arguments.
pm-op() {
    local pm op cmd
    pm="$(detect)" || return 1
    op="$1"
    shift
    cmd="$(get-data "pm/$op/$pm" -path)" ||
        fail "'get-data' failed."
    [ -f "$cmd" ] ||
        fail "Can't $op with $pm."
    msg "Running action: $op/$pm $*"
    [ -n "$DEBUG" ] ||
        . "$cmd"
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
            # Most commands don't need anything special.
            pm-op "$arg" "$@" ;;
    esac
}

main "$@"
