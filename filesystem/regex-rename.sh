#!/bin/bash
# regex-rename.sh
# Rename files by regex pattern.

# globals
declare DEBUG
declare DIRS
declare DRY
declare NORECURSE
declare QUIET
declare RELINK

declare MATCH
declare RENAME

# b text
##
# Bold the given text and echo it back.
b() { echo -e "\e[1m$*\e[0m"; }

usage() {
    # Example match and rename patterns
    local match='(.*[^ -])[ -]* ([0-9]{2}) [ -]*([^ -].*)'
    local rename='\2 - \1 - \3'
    # Name of script
    local name="$(basename "$0")"
    # Show usage message
    echo -e "$name [options ...] match-regex rename-regex path [...]

Apply regex find/rename on file names under given path(s).

For example,
\e[1m$name '$match' '$rename' /path/to/music\e[0m
could rewrite track file names to start with their track number so a
file-based audio player plays them in the right order.

Options
$(b --debug)       Show extra info.
$(b --dirs)        Also rename directories.
$(b --dry)         Don't actually run the commands.
$(b --no-recurse)  Only process given paths, not folder contents.
$(b --quiet)       Don't show commands.
$(b --relink)      Change symlink targets instead of names.
"
}

dbg() {
    [ -n "$DEBUG" ] && echo -e "\e[1mDebug:\e[0m $*"
}

cmd() {
    [ -z "$QUIET" ] && echo -e "\e[1m$*\e[0m"
    [ -z "$DRY" ] && "$@"
}

# escape-slashes string
##
# Echo back the string, turning each '/' into '\/'.
escape-slashes() { echo "$1" | sed -r 's!/!\\/!g'; }

# rename location
##
# Recursively renames all files under location that match the $MATCH
# pattern to new names following the $RENAME pattern.
rename() {
    # recurse
    dbg "rename() $1"
    local x
    if [ -d "$1" ] && [ -z "$NORECURSE" ]; then
        shopt -s nullglob  # don't loop over invalid "$1/*"
        for x in "$1"/*; do
            rename "$x"
        done
    fi

    # handle the item
    local loc="$1" dir name target new
    dir="${loc%/*}"
    name="${loc##*/}"
    dbg "rename() dir=$dir   name=$name"
    if [ "$RELINK" = "true" ]; then
        if [ -L "$loc" ]; then
            target="$(readlink "$loc")"
            dbg "rename() -> target=$target"
            new="$(echo "$target" | sed -r "s/$MATCH/$RENAME/")"
            if [ "$target" != "$new" ]; then
                cmd rm "$loc"
                cmd ln -s "$new" "$loc"
            fi
        fi
    elif [ ! -d "$loc" ] || [ "$DIRS" = "true" ]; then
        new="$(echo "$name" | sed -r "s/$MATCH/$RENAME/")"
        [ "$name" != "$new" ] && cmd mv "$dir/$name" "$dir/$new"
    fi
}

main() {
    local path
    local -a paths
    while [ "$#" -ge 1 ]; do
        case "$1" in
            --debug)
                DEBUG=true
                ;;
            --dirs)
                DIRS=true
                ;;
            --dry)
                DRY=true
                ;;
            --no-recurse)
                NORECURSE=true
                ;;
            --quiet)
                QUIET=true
                ;;
            --relink)
                RELINK=true
                ;;
            *)
                break
                ;;
        esac
        shift
    done
    [ "$#" -ge 3 ] || { usage && exit 1; }
    MATCH="$(escape-slashes "$1")"
    RENAME="$(escape-slashes "$2")"
    shift 2
    paths=("$@")
    dbg "DEBUG=$DEBUG  DRY=$DRY  QUIET=$QUIET  RELINK=$RELINK"
    dbg "MATCH='$MATCH'  RENAME='$RENAME'"
    dbg "paths=(${paths[*]})"
    for path in "${paths[@]}"; do
        rename "$path"
    done
}
main "$@"
