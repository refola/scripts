#!/bin/sh
## sc.sh
usage="sc /path/to/script.sh [...]

Run ShellCheck on each passed script path, from the respective
directory of each script, enabling source-following, and disabling
checks that sc's author personally finds overzealous."

[ -z "$1" ] && echo "$usage" && exit 1

for script in "$@"; do
    cd "$(dirname "$script")"
    # SC2155: Declare and assign separately to avoid masking return values.
    shellcheck --exclude=SC2155 -x "$(basename "$script")"
done
