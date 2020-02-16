#!/usr/bin/env bash
##diff-sort.sh
# Use `diff` to compare directory trees, then move unique and
# conflicting items into "_uniq" and "_conf" folders.

# "shopt -s lastpipe" prevents prevents both these ShellCheck errors
# by having Bash run pipelines in the same shell.
##
# shellcheck disable=SC2030,SC2031
shopt -s lastpipe # run loop in same shell so var changes persist

USAGE="$0 [options ...] A B
$0 [options ...] --flatten A

First way: Use 'diff' to compare directories A and B, then move unique
and conflicting items into '_uniq' and '_conf' folders, respectively.

Second way: Remerge '_uniq' and '_conf' folders.

Options:
--dry    Do a 'dry run' that doesn't change the given folders.
--debug  Show extra debug output.
--quiet  Don't show commands being ran.
"

# Global vars, set in main()
DEBUG= # Should we show debug messages?
DRY=   # Should we skip actually running commands?
TEMP=  # Where should we save diff's output?
QUIET= # Should we skip echoing commands?

# fatal reason-for-failure [...]
##
# Shows everything given on STDERR and exits the script.
fatal() {
    echo -e "\e[1mError:\e[0m $*" >&2
    [ -z "$DEBUG" ] &&
        echo -e "Try rerunning with \e[1m--debug\e[0m for more info."
    exit 1
}

# dbg message [...]
##
# Shows passed args on STDERR iff DEBUG is set.
dbg() {
    [ -n "$DEBUG" ] && echo -e "\e[1mDebug:\e[0m $*" >&2
}

# cmd command [args ...]
##
# Normal mode: Prints and runs command with given args.
#
# Dry run mode: Prints command without running it.
##
# When to use cmd in this script: For and only for things that would
# change the user-passed folders.
cmd() {
    [ -z "$QUIET" ] && echo -e "\e[1m$*\e[0m"
    [ -z "$DRY" ] && "$@"
}

# compare A B
##
# Writes a diff-generated comparison of directories A and B to $TEMP.
compare() {
    dbg "Running recursive diff of '$1' and '$2' and saving to '$TEMP'."
    diff --recursive --brief "$1" "$2" > "$TEMP"
}

# conf A B diff-line
##
# Moves conflicting contents of directories A and B to respective
# '_conf' folders, based on the given line produced by the 'diff'
# command.
##
# TODO: Remove ShellCheck directive after getting a newer
# top-level-directive-supporting version to compile.
##
# shellcheck disable=SC2030,SC2031
conf() {
    local a="$1" b="$2" line="$3" patha pathb name path
    dbg "conf: line='$line'"
    local IFS=$'\t'
    echo "$line" | sed -r "s!Files $a/(.*) and $b/(.*) differ!\1\t\2!g" |
        read -r patha pathb
    dbg "conf: patha='$patha', pathb='$pathb'"
    [ "$patha" = "$pathb" ] ||
        fatal "Nonidentical paths '$patha' and '$pathb'."
    name="${patha##*\/}" # part after last '/'
    dbg "conf: name='$name'"
    path="${patha%$name}" # part before and including last '/'
    dbg "conf: path='$path'"
    cmd mkdir -p "$a/_conf/$path" "$b/_conf/$path"
    # There's no '/' between $path and $name because it's already in
    # $path iff $path is nonempty.
    cmd mv "$a/$path$name" "$a/_conf/$path"
    cmd mv "$b/$path$name" "$b/_conf/$path"
}

# uniq A diff-line
##
# Moves unique item in directory A to '_uniq' folder, based on given
# line from 'diff'.
# shellcheck disable=SC2030,SC2031
uniq() {
    local d="$1" line="$2" path name
    dbg "uniq: line='$line'"
    local IFS=$'\t'
    # "x" in replacement to let "read" detect empty path
    echo "$line" | sed -r "s!Only in $d(/?.*): (.*)!x\1\t\2!g" |
        read -r path name
    path="${path#x}" # strip added "x"
    dbg "uniq: path='$path' name='$name'"
    # There's no '/' before $path because it's already in $path iff
    # $path is nonempty.
    cmd mkdir -p "$d/_uniq$path/"
    cmd mv "$d$path/$name" "$d/_uniq$path/"
}

# sort A B
##
# Uses 'diff' output in $TEMP to sort contents of directories A and B
# into shared contents (unmoved), unique contents (moved to respective
# '_uniq' folders) and conflicting contents (moved to respective
# '_conf' folders), but without moving existing '_uniq' or '_conf'
# folders.
##
# TODO: Remove ShellCheck directive after getting a newer
# top-level-directive-supporting version to compile.
##
# shellcheck disable=SC2030,SC2031
sort() {
    local a="$1" b="$2"
    conf_pre="Files $a"
    conf_pre_conf="Files $a/_conf"
    uniq_pre_a="Only in $a"
    uniq_pre_b="Only in $b"
    uniq_pre_a_uniq="Only in $a/_uniq"
    uniq_pre_b_uniq="Only in $b/_uniq"
    while read -r line; do
        [ "${line:0:${#conf_pre}}" = "$conf_pre" ] &&
            [ "${line:0:${#conf_pre_conf}}" != "$conf_pre_conf" ] &&
            conf "$a" "$b" "$line"
        [ "${line:0:${#uniq_pre_a}}" = "$uniq_pre_a" ] &&
            [ "${line:0:${#uniq_pre_a_uniq}}" != "$uniq_pre_a_uniq" ] &&
            uniq "$a" "$line"
        [ "${line:0:${#uniq_pre_b}}" = "$uniq_pre_b" ] &&
            [ "${line:0:${#uniq_pre_b_uniq}}" != "$uniq_pre_b_uniq" ] &&
            uniq "$b" "$line"
    done < "$TEMP"
}

# flatten A
##
# Merge '_conf' and '_uniq' folder contents back into given
# directory's structure, effectively undoing this script's effect on
# that directory.
flatten() {
    _flatten "$1" _conf ''
    _flatten "$1" _uniq ''
}
# _flatten A type subpath
##
# Recursively move contents of A/type/subpath to A/subpath.
_flatten() {
    local a="$1" t="$2" s="$3"
    local src="$a/$t/$s" target="$a/$s"
    local xs x
    dbg "_flatten: a='$a', type='$t', subpath='$s'"
    dbg "_flatten: source='$src', target='$target'"
    # end recursion
    if [ ! -e "$target" ]; then
        cmd mkdir -p "$(dirname "$target")"
        cmd mv "$src" "$target"
        return $?
    fi
    [ -d "$src" ] ||
        fatal "_flatten: source '$src' is non-directory corresponding to existant target '$target'"
    cd "$src" || fatal "_flatten: could not 'cd' to source '$src'"
    shopt -s dotglob # necessary for './*' to get everything
    xs=(./*)
    dbg "_flatten: xs=(${xs[*]})"
    cd - >/dev/null || # don't break relative paths
        fatal "_flatten: could not 'cd' back"
    # start recursion
    for x in "${xs[@]}"; do
        x="${x#./}" # strip leading './'
        if [ -z "$s" ]; then
            _flatten "$a" "$t" "$x"
        else
            _flatten "$a" "$t" "$s/$x"
        fi
    done
    # remove now-empty directory
    cmd rmdir "$src" ||
        fatal "_flatten: could not remove directory '$src' which should be empty"
}

# main "$@"
##
# Parse args and run appropriate functions appropriately.
main() {
    while [ "$#" -gt "2" ]; do
        case "$1" in
            --dry)   DRY=true                     ;;
            --debug) DEBUG=true                   ;;
            --quiet) QUIET=true                   ;;
            *)       fatal "Unknown option '$1'." ;;
        esac
        shift
    done
    dbg "main: DRY='$DRY', DEBUG='$DEBUG'"
    if [ "$#" != "2" ]; then
        echo "$USAGE"
        exit 1
    fi
    if [ "$1" = "--flatten" ]; then
        flatten "$2"
    else
        TEMP="$(mktemp)" || fatal "Could not 'mktemp'."
        compare "$1" "$2"
        sort "$1" "$2"
        rm "$TEMP"
    fi
}

main "$@"
