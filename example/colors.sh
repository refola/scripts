#!/bin/bash
## colors.sh
# Echo a reference for color codes.

## Usage: row outer-code inner-code-prefix name
row() {
    echo -n "$3"
    local i
    for i in {0..7}; do
        echo -en "\e[0;$1;$2${i}m$2$i\e[0m "
    done
    echo
}

## Usage: block code name
# Show a block of color codes, combined with "code", and preceded with
# printing "name" in "code".
block() {
    if [ "$1" = "5" ]; then
        echo "$1: $2"
        echo "I don't want this to blink"
        echo "so I'm skipping this one."
        echo
        return 1
    fi
    local i
    local j
    echo -e "$1: \e[0;${1}m$2\e[0m"
    row "$1" 03 "normal:     "
    row "$1" 04 "background: "
    row "$1" 09 "intense:    "
    row "$1" 10 "intense bg: "
    echo
}

info="This script prints of reference formatting codes for text in
scripts. The number before each block is a formatting code. The
numbers inside the blocks show what happens when that formatting code
is applied after the code before the block.

To format your text, use 'echo -e', prefix your text by the magic
code-enabling string, and follow your text by the null-code
string. The code-enabling strings are made by surrounding the codes by
'\e[' and 'm', and separating the codes by ';'. Here's an example:

echo -e '\e[0;3;4;30;105mItalic, underlined, and dark on pink\e[0m'

Note the '0;' at the beginning of the code-enabling string. That's to
clear out other formatting that may have gone before. Color codes
replace other color codes of the same type (e.g., foreground vs
background), but '\e[0m' and such is the only way I know to clear
other formatting, and it clears all formatting."

if [ "$1" = "info" ]; then
    echo "$info"
    echo
else
    echo "Here's the color code reference. Run '$(basename "$0") info'"
    echo "for information about how *nix console color codes work."
    echo
    block 0 normal
    block 1 bold
    block 3 italic
    block 4 underline
    block 5 blink
    block 7 "perma-swap foreground and background"
fi
