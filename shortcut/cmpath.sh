#!/bin/bash
## cmpath.sh
# Output actual paths commands, resolving symlinks.

# Show message(s) on stderr and exit.
err() { echo "$*" >&2; exit 1; }

# Make sure at least one path was passed, or show usage.
[ -z "$1" ] && err "$(cmpath "$0") command [...]
Show commands' locations after resolving symlinks."

# Find and show the paths.
for x in "$@"; do
    path="$(which -- "$x")" ||
        err "Could not find path for '$x'."
    real="$(readlink -f "$path")" ||
        err "Broken symlink for '$x' at '$path'?"
    echo "$real"
done
