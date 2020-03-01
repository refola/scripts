#!/usr/bin/env bash
#transient-caches.sh
# Make and unmake transient ~/.cache/* folders under /tmp

loc="$HOME/.cache"
tmp_loc="/tmp/$USER-$UID/.cache-transient"

# Directories under $loc for which to make transient
##
# NOTE: Certain entries start with "^#" to let them be skipped due to
# potential login issues if the cache is unavailable before this
# script is ran. The problem is that if this script enables transient
# cache and /tmp is cleared without this script disabling transient
# cache, then the desktop environment is left with symlinks to
# nonexistent directories, hence can't write under them during login
# before on-login scripts are ran.
dirs=($(get-data transient-caches/paths | grep -v '^#'))

debug() {
    local x
    for x in "${dirs[@]}"; do
        echo "dir: '$x'"
    done
}

usage="Usage: $0 {help|nuke|off|on|usage} [...]

Manages transient caches where symlinks in '$loc/*' point to real
folders in '$tmp_loc'.

Action  Meaning
  help  Show this usage info and exit.
  nuke  Clear all handled cache locations.
   off  Turn off transient caches by moving caches
        from '$tmp_loc/*' to '$loc'.
    on  Turn on transient caches by moving caches
        from '$loc/*' to '$tmp_loc'.
 usage  Alias for 'help'.

Note: That both 'off' and 'on' actions are idempotent. That is,
running the same option repeatedly has the same effect as running it
once, so it's safe to run the desired action when unsure of current
state.

Note: Because the 'nuke' action clears symlinks of processed names,
following it by 'off' is idempotent.

"

# Show usage info
usage() {
    echo "$usage"
}

# Make sure that given directories are either nonempty or
# nonexistent. With '-p' as a first argument, also attempt removing
# parents with the same logic.
clean-empty-dirs() {
    local arg='' x
    if [ "${1/\/*/}" = "$1" ]; then
        arg="$1"
        shift
    fi
    for x in "$@"; do
        # '$arg' needs to be unquoted so it's skipped when empty.
        # shellcheck disable=SC2086
        [ -d "$x" ] && rmdir $arg --ignore-fail-on-non-empty "$x"
    done
}

# Set temp stuff to be in /tmp, idempotently
enable() {
    mkdir -p "$tmp_loc"
    local x
    for x in "${dirs[@]}"; do
        [ -L "$loc/$x" ] && [ -d "$tmp_loc/$x" ] && continue # Already done.
        [ -d "$loc/$x" ] && mv "$loc/$x" "$tmp_loc/" # Move existing.
        [ ! -e "$tmp_loc/$x" ] && mkdir -p "$tmp_loc/$x" # Make sure it exists.
        [ ! -e "$loc/$x" ] && ln -s -T "$tmp_loc/$x" "$loc/$x" # Set symlink.
    done
}

# Set temp stuff to not be in /tmp, idempotently
disable() {
    local x
    for x in "${dirs[@]}"; do
        [ -L "$loc/$x" ] && rm "$loc/$x" # Remove symlink.
        [ -d "$tmp_loc/$x" ] && mv "$tmp_loc/$x" "$loc/" # Move back.
        clean-empty-dirs "$loc/$x"
        [ ! -e "$tmp_loc/$x" ] && continue # Should be done by now.
        echo "Error: '$tmp_loc/$x' exists after removal actions."
        echo "Aborting 'disable()'."
        return 1
    done
    clean-empty-dirs -p "$tmp_loc" # Cleanup.
}

# Remove cache data from both locations
nuke() {
    local x
    for x in "${dirs[@]}"; do
        # Using ':?' cancels command with error if the variable is
        # unset, preventing accidental calling of 'rm -rf /'.
        [ -d "$tmp_loc/$x" ] && rm -rf "${tmp_loc:?}/$x" # /tmp caches
        [ -d "$loc/$x" ] && rm -rf "${loc:?}/$x" # ~/.cache caches
        [ -L "$loc/$x" ] && rm "$loc/$x" # ~/.cache dangling symlinks
    done
    clean-empty-dirs -p "$tmp_loc"
}

# Handle args and run appropriate action.
main() {
    if [ -z "$1" ]; then
        usage
        exit 1
    fi

    while [ ! -z "$1" ]; do
        case "$1" in
            dbg)
                debug
                ;;
            help|usage)
                usage
                ;;
            nuke)
                nuke
                ;;
            on)
                enable
                ;;
            off)
                disable
                ;;
            *)
                usage
                ;;
        esac
        shift
    done
}

main "$@"
