#!/usr/bin/env bash

## GLOBAL VARIABLES

# This is for setting which runners are prefered for which programs.
# `runners[program]=runner` sets `program` she-bangs to use `runner`.
# `runners["$default"]=runner` sets unspecified programs to use `runner`.
# Not setting `runners["$default"]` leaves unspecified cases unchanged.
declare -A runners

# Special value for default programs. This is set to 2*8*16=256 bits
# of randomness to avoid name collision, as a shell-style substitute
# for `gensym` or other languages' more direct solutions to this
# problem.
default="$RANDOM:$RANDOM:$RANDOM:$RANDOM:$RANDOM:$RANDOM:$RANDOM:$RANDOM:$RANDOM:$RANDOM:$RANDOM:$RANDOM:$RANDOM:$RANDOM:$RANDOM:$RANDOM"

# Prefix for using `env`
env="#!/usr/bin/env "

# Prefix for using `/bin`
bin="#!/bin/"

# List of all prefixes
prefixes=("$env" "$bin")

# Convenience function
err() {
    echo "$@" >&2
    return 1
}

# Get the name of the program after whatever prefix is in the shebang
get-prog() {
    local h l
    h="$(head -n1 "$1")" || return 1
    for prefix in "${prefixes[@]}"; do
        l="${#prefix}"
        if [ "${h:0:$l}" = "$prefix" ]; then
            echo "${h:$l}"
            return 0
        fi
    done
    return 1
}

# Change the shebang prefix based on detected program name and global
# `runners` array
change-shebang-prefixes() {
    local x prog runner
    for x in "$@"; do
        if [ -d "$x" ]; then
            change-shebang-prefixes "$x"/*
        elif prog="$(get-prog "$x")"; then
            for runner in "${runners[$prog]}" "${runners["$default"]}"; do
                if [ -n "$runner" ]; then
                    echo sed -i "s\\$prog\\$runner\\" "$x"
                    continue 2
                fi
            done
            err "Couldn't get runner for '$1'. Leaving it unchanged."
        else
            err "Couldn't get program for '$1'. Leaving it unchanged."
        fi
    done
}

# Set global `runners` array.
env-all() { runners["$default"]="$env"; }
env-most() {
    runners["$default"]="$env"
    # Stop spurious "sh is referenced but not assigned" from shellcheck.
    # shellcheck disable=SC2154
    runners[sh]="$bin"
}
bin-sh() {
    # There's no shellcheck error in this identical line.
    runners[sh]="$bin"
}
bin-all() { runners["$default"]="$bin"; }

# Show usage information.
usage() {
    echo "Usage:
$0 command files [...]
$0 { help | h | --help | -h }

Update files' she-bang lines (when the first line starts with '#!/')
according to given command. Valid commands are as follows.

env-all    Change all she-bangs to use '/usr/bin/env' to get the program
            that runs the script.
env-most   Change most she-bangs to use '/usr/bin/env' to get the
            program that runs the script. The exception is scripts ran
            by 'sh', which are set to use '/bin/sh'.
bin-sh     Change 'sh' she-bangs to use '/bin/sh' while leaving others
            unchanged.
bin-all    Change all she-bangs to use '/bin/'.
"
}

# Pretend that there's a functional shell script entry point.
main() {
    case "$1" in
        env-all|env-most|bin-sh|bin-all)
            $1
            shift
            change-runners "$@"
            ;;
        help|h|--help|-h)
            usage
            exit
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
