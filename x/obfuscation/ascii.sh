#!/usr/bin/env bash
# ascii.sh
##
# Convert between ascii and various encodings people on the internet
# are prone to use

nibble2hex() {
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

from-binary() {
    local text
    local -a bytes
    local word nibble byte
    text="$(echo "$*" | grep -Eo '[01]' | tr -d '\n')"
    for word in $(echo "$text" | fold --width=8); do
        byte=
        for nibble in $(echo "$word" | fold --width=4); do
            byte="$byte$(nibble2hex "$nibble")"
        done
        echo -en "\x$byte"
    done
}

# hard-code first use case for now
from-binary "$@" |
    cat -v # dispell escape-code magic
echo # obligatory newline so the prompt is okay
