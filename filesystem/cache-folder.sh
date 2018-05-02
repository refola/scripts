#!/usr/bin/env bash
# Cache the given folder(s) or $PWD.

# Cache a single folder.
cache-one() {
    echo "Caching folder $1."
    find "$1" -type f -exec cat {} > /dev/null +
}

if [ "$#" = "0" ]; then
    echo "No folder passed, so caching \$PWD."
    cache-one "$PWD"
else
    for dir in "$@"; do
        cache-one "$dir"
    done
fi
