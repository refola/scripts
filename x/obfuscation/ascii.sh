#!/usr/bin/env bash
# ascii.sh
##
# Convert between ascii and various encodings people on the internet
# are prone to use

nibble2hex() {
    # TODO: figure out base conversion with, e.g., 'dc' or 'bc'
    # commands or maybe even shell parameter expansion; then replace
    # with 'change-base' function
    case "$1" in
        0000) echo 0;;
        0001) echo 1;;
        0010) echo 2;;
        0011) echo 3;;
        0100) echo 4;;
        0101) echo 5;;
        0110) echo 6;;
        0111) echo 7;;
        1000) echo 8;;
        1001) echo 9;;
        1010) echo A;;
        1011) echo B;;
        1100) echo C;;
        1101) echo D;;
        1110) echo E;;
        1111) echo F;;
        *)
            echo "Aborting on bad nibble '$1'" >&2
            exit 1
            ;;
    esac
}

from-bin() {
    local input
    local word nibble byte
    input="$(echo "$*" | grep -Eo '[01]' | tr -d '\n')"
    for word in $(echo "$input" | fold --width=8); do
        byte=
        for nibble in $(echo "$word" | fold --width=4); do
            byte="$byte$(nibble2hex "$nibble")"
        done
        echo -en "\x$byte"
    done
}

from-hex() {
    local input byte
    input="$(echo "$*" | grep -Eio '[0-9A-F]' | tr -d '\n')"
    for byte in $(echo "$input" | fold --width=2); do
        echo -en "\x$byte"
    done
}

## filter chars text [...]
# filter text to only given chars, specified via 'tr' syntax (ranges,
# some backslash escapes, some named ranges; see 'man tr')
strip() {
    local chars="$1"
    shift
    echo "$*" | tr -dc "$chars" # delete complement of given chars
}

## score pattern text [...]
# score each text as matching the given filter pattern
## score formula:
# (match length)^2 * 1000 / (pattern length)
score() {
    local pattern="$1" lpattern text match lmatch
    lpattern=${#pattern} # must assign on own line because $pattern is unset at time of running 'local ...'
    dbg "score() pattern=$pattern  lpattern=$lpattern"
    shift
    for text in "$@"; do
        match="$(strip "$pattern" "$text")"
        lmatch=${#match}
        dbg "score() match=$match lmatch=$lmatch"
        echo $((lmatch**2 * 1000 / lpattern))
    done
}

dbg() { [ -n "$DEBUG" ] && echo "$@" >&2; }

usage() {
    echo "ascii [options] text [...]

convert the given text to ascii, trying to automatically determine
obfuscation method if unspecified

options:
--bin     assume binary obfuscation (ascii '0' and '1' characters)
--debug   show extra debug output
--hex     assume hexadecimal obfuscation
"
}

main() {
    local text bin_score=0 hex_score=0 max_score=0 fn=''
    while true; do
        case "$1" in
            --bin) fn=from-bin;;
            --debug) DEBUG=true;;
            --hex) fn=from-hex;;
            *) break;;
        esac
        shift
    done
    text="$*"
    if [ -z "$text" ]; then
        usage
        exit 1
    fi
    if [ -z "$fn" ]; then
        bin_score="$(score 01 "$text")"
        hex_score="$(score 0-9a-fA-F "$text")"
        max_score="$(echo -e "$bin_score\n$hex_score" | sort -n | tail -n1)"
        dbg "main() score are: bin=$bin_score  hex=$hex_score  max=$max_score"
        case "$max_score" in
            "$bin_score") fn=from-bin;;
            "$hex_score") fn=from-hex;;
            *) echo "fail: max score not in scores list" && continue
        esac
    fi
    dbg "main() chose function fn=$fn"
    $fn "$text" |
        cat -v # dispell escape-code magic
    echo # obligatory newline so the prompt is okay
}

main "$@"
