#!/bin/bash
# regex-rename.sh
# Rename files by regex pattern.

usage() {
    # Example match and rename patterns
    local match='(.*[^ -])[ -]* ([0-9]{2}) [ -]*([^ -].*)'
    local rename='\2 - \1 - \3'
    # Show usage message
    echo -e "$0 [options ...] match-regex rename-regex path [...]

Apply regex find/rename on file names under given path(s).

For example,
\e[1m$0 '$match' '$rename' /path/to/music\e[0m
could rewrite track file names to start with their track number so a
file-based audio player plays them in the right order.

Options
\e[1m--debug\e[0m  Show extra info.
\e[1m--dry\e[0m    Don't actually run the commands.
\e[1m--quiet\e[0m  Don't show commands.
"
}

dbg() {
    [ -n "$DEBUG" ] && echo -e "\e[1mDebug:\e[0m $*"
}

cmd() {
    [ -z "$QUIET" ] && echo -e "\e[1m$*\e[0m"
    [ -z "$DRY" ] && "$@"
}

# rename location
##
# Recursively renames all files under location that match the $MATCH
# pattern to new names following the $RENAME pattern.
rename() {
    dbg "rename() $1"
    local d="${1%/}" x y
    for x in "$d"/*; do
        x="${x#"$d/"}"
        dbg "rename() $1: x=$x"
        if [ -d "$d/$x" ]; then
            rename "$d/$x"
        else
            y="$(echo "$x" | sed -r "s/$MATCH/$RENAME/")"
            [ "$x" != "$y" ] && cmd mv "$d/$x" "$d/$y"
        fi
    done
}

main() {
    local path
    while [ "$#" -ge 1 ]; do
        case "$1" in
            --debug)
                DEBUG=true
                ;;
            --dry)
                DRY=true
                ;;
            --quiet)
                QUIET=true
                ;;
            *)
                break
                ;;
        esac
        shift
    done
    [ "$#" -ge 3 ] || { usage && exit 1; }
    MATCH="$1"
    RENAME="$2"
    shift 2
    PATHS=("$@")
    dbg "DEBUG=$DEBUG  DRY=$DRY  QUIET=$QUIET"
    dbg "MATCH='$MATCH'  RENAME='$RENAME'"
    dbg "PATHS=(${PATHS[*]})"
    for path in "${PATHS[@]}"; do
        rename "$path"
    done
}
main "$@"
