#!/bin/bash
## pcd.sh
# Emulate `cd` with `pushd` side effects.

# `cd` with extra args or with "-" is special and can't be emulated so
# well with pushd.
if [ $# != 1 ] || [ "$1" = "-" ]; then
    # This is sourced and we don't want to exit the interactive session.
    # shellcheck disable=SC2164
    cd "$@"
else
    # Other than side effects on `popd` and `dirs`, this looks the
    # same as `cd`.
    pushd "$1" >/dev/null
fi
