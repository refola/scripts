#!/usr/bin/env bash

# pm.sh - package manager frontend for multiple distros

usage="Usage: $(basename "$0") [operation [package ...]]

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

Currently supported package managers:
* apt-get (Debian, *buntu, Mint, etc)
* ccr (Chakra)
* pacman (Arch, Chakra, Kaos, etc)
* zypper (openSUSE)

Limitations:
* The info command doesn't yet support zypper.
* This works by checking for the existence of a package manager, but
  it should check 'ID=' and 'ID_LIKE' in /etc/os-release instead.

Developer information:
* Please see $(get-data pm/README -path) for how package manager
  operations are defined.
"

## Usage: fatal args ...
# Runs err with given args and exits the script.
fatal() {
    echo -e "\e[1;4;91mError\e[0m: $*" 1>&2
    exit 1
}

# Package managers, split by sudo-using status
non_sudo_pms=($(get-data "pm/non-sudo-pms")) ||
    fatal "Could not get list of non-sudo package managers."
sudo_pms=($(get-data "pm/sudo-pms")) ||
    fatal "Could not get list of sudo-using package managers."
# Non-sudo pms first to minimize directly calling sudo.
pms=("${non_sudo_pms[@]}" "${sudo_pms[@]}")

## Usage: msg args ...
# Echos args in fancy style, so it's clear that it's from pm.
msg() {
    echo -e "\e[1;34mpm: \e[0;32m$1\e[0m"
}

## Usage: maybe-sudo command
# Returns 0 if calls to command should be prefixed with "sudo",
# otherwise returns 1.
maybe-sudo() {
    if [ "$EUID" = "0" ]; then
        return 0
    else
        local zero="${sudo_pms[*]}"
        local one="${non_sudo_pms[*]}"
        local test
        test="$(echo -e "$zero\n$one" | grep -e "\b$1\b")"
        case "$test" in
            "$zero")
                return 0 ;;
            "$one")
                return 1 ;;
            *) # Blindly assume that unknown commands don't need sudo.
                return 1 ;;
        esac
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
    fatal "No package manager found"
    exit 1
}

## Usage: pm-op operation [args ...]
# Get and run the appropriate commands for the system's package
# manager to do the requested operation with the given arguments.
pm-op() {
    local pm
    pm="$(detect)" || return 1
    local op="$1"
    shift
    # $args is used in the eval.
    # shellcheck disable=SC2034
    local args="$*"
    local no_sudo
    if [ -f "$(get-data "pm/$op/.no-sudo" -path)" ]; then
        no_sudo="true"
    fi
    local raw_cmds
    raw_cmds="$(get-data "pm/$op/$pm")" ||
        fatal "Can't $op with $pm."
    local IFS=$'\n'
    for line in $raw_cmds; do
        # TODO: Eval is evil! The Devil is in the details! Be careful
        # what you wish for! (Double-check that this correctly
        # converts $vars without doing anything more dangerous.)
        local cmd
        cmd="$(eval "echo \"$line\"")" ||
            fatal "Could not convert '$cmd'"
        local IFS=' ' # Split on spaces ...
        ## ... and let set have the intended space-separated args
        ## contained in $1 without shellcheck complaining.
        # shellcheck disable=SC2086
        set $cmd
        cmd=("$@")
        if [ -z "$no_sudo" ] && maybe-sudo "${cmd[0]}"; then
            cmd=("sudo" "${cmd[@]}")
        fi
        msg "Running ${cmd[*]}"
        "${cmd[@]}" || fatal "Command did not complete successfully."
    done
}

## Usage: main "$@"
# Do everything.
main() {
    if [ -z "$1" ]; then
        echo "$usage"
        exit 1
    fi
    local op="$1"
    shift
    case "$op" in
        det|detect)
            local manager
            manager="$(detect)" || exit 1
            msg "Package manager: $manager" ;;
        'in'|install)
            msg "Upgrading system before install."
            pm-op up
            pm-op 'in' "$@" ;;
        h|'help')
            echo "$usage" ;;
        *)
            # Most commands don't need anything special. Just gotta
            # check that they exist.
            if [ -d "$(get-data "pm/$op" -path)" ]; then
                pm-op "$op" "$@"
            else
                msg "Unknown operation: $op"
                echo "$usage"
                exit 1
            fi ;;
    esac
}

main "$@"
