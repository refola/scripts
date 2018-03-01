#!/bin/bash
## colors.sh
# Echo a reference for color codes.

## Usage: row outer-code inner-code-prefix name
# Show a row of color codes.
row() {
    echo -n "$3"
    local i
    for i in {0..7}; do
        echo -en "\e[0;$1;$2${i}m$2$i\e[0m "
    done
    echo "(clear row's codes with $4)"
}

## Usage: block code name clearer
# Show a block of color codes, combined with "code", and preceded with
# printing "name" in "code".
block() {
    # Explicitly ignore blinking, with error
    if [ "$1" = "5" ]; then
        echo "$1: $2 (clear with $3)"
        echo "This would blink, but that's distracting so I'm skipping it."
        echo
        return 1
    fi

    # Otherwise, business as usual
    local i
    local j
    echo -e "$1: \e[0;${1}m$2\e[${3}m (clear with $3)"
    row "$1" 03 "normal:     " "38 or 39"
    row "$1" 04 "background: " "48 or 49"
    row "$1" 09 "intense:    " "38 or 39"
    row "$1" 10 "intense bg: " "48 or 49"
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

Note the '0;' at the beginning of the code-enabling string. This
clears out all possible previously-entered formatting that may have
gone before. Color codes replace other color codes of the same type
(e.g., foreground vs background), and particular codes undo the effect
of particular types of codes, but '\e[0m' is the all-purpose
formatting reset code."

if [ "$1" = "info" ]; then
    echo "$info"
    echo
else
    echo "Here's the color code reference. Run '$(basename "$0") info'"
    echo "for information about how *nix console color codes work."
    echo
    #     Nr  Effect      Clearer
    block 0   normal      20
    block 1   bold        21
    block 2   faint       22
    block 3   italic      23
    block 4   underline   24
    block 5   blink       25
    block 6   nothing?    26
    block 7   bg-fg-swap  27
    block 53  overline    55
fi
