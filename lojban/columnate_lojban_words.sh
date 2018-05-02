#!/usr/bin/env bash

# Make files with Lojban words formatted in alphabetical order in
# columns (e.g., the first gismu column will always contain "bacru
# badna badri ..."), automatically finding suitable row lengths based
# on (very roughly) approximating the golden ratio.

usage="$(basename "$0") [ratio | min-ratio max-ratio]

Converts Lojban words in $in_dir into nicely formatted columns, saving them in the configured directory.
"

# Locations to read and write word files, set in main bacause they
# might not be defined yet.
in_dir=""
out_dir=""

# Default ratio limits for filtering magic grid sizes, approximating
# the golden ratio of Phi = 1+sqrt(5))/2 ~= 1.618. Note that due to
# Bash lacking a native decimal type, these limits are multiplied by
# 10 (limiting precision).
min_ratio="13"
max_ratio="19"

# Print messages
msg() { echo -e "$@" 1>&2; }

# Prints messages iff verbose is enabled.
dbg() {
    if [ "$verbose" = "true" ]; then
        msg "\e[0;1mDebug:\e[0m $*"
    fi
}
verbose="false"
#verbose="true"
dbg "verbose=$verbose"

## Usage: is-magic-ratio big small
# Returns true (0) if big/small rounds to to anything between the set
# ratios.
is-magic-ratio() {
    for r in $(seq "$min_ratio" "$max_ratio"); do
        if [[ $(($1*10/$2)) -eq $r ]]; then
            return 0;
        fi
    done
    return 1
}

## Usage: magic-ratios number [...]
# Outputs all pairs of factors of the given numbers that result in a
# "magic ratio" where the bigger factor divided by the smaller one is
# "close enough" to Phi.
magic-ratios() {
    if [[ "$#" -eq "0" ]]; then
        return
    fi
    local x
    for x in $(seq "$(sqrt "$1")"); do
        local y="$(($1/x))"
        if [[ x -gt y ]]; then
            break
        fi
        if [[ x*y -eq "$1" ]]; then
            if is-magic-ratio "$y" "$x"; then
                echo "$y" "$x"
            fi
        fi
    done
    shift
    magic-ratios "$@"
}

## Usage: make-columns n
# Reads in standard input and spits it back out in space-separated
# columns. It's not nearly as fancy as the column command, but it
# actually makes columns and makes as many as you want.
make-columns() {
    local x
    local output
    while true; do
        if read -r x; then
            output="$x"
        else
            return
        fi
        for ((i=1; i<$1; i++)); do
            if read -r x; then
                output+=" $x"
            else
                echo "$output"
                return
            fi
        done
        echo "$output"
    done
}

## Usage: get-column contents n
# Gets the nth column from contents. This requires contents to be
# formatted with space-separated columns and newline-separated rows.
get-column() {
    local rows="$1"
    local n="$2"
    local row
    local IFS=$'\n'
    for row in $rows; do
        local IFS=" "
        # shellcheck disable=SC2086
        set $row # "set" needs this unquoted
        echo -n "${!n} "
    done
    echo
}

## Usage: transpose matrix
# Echos the transpose of the given matrix. The matrix must be
# formatted with space-separated columns and newline-separated rows.
transpose() {
    local matrix="$1"
    # Get number of columns from first row
    local IFS=$'\n'
    # shellcheck disable=SC2086
    set $matrix # "set" needs this unquoted
    local IFS=' '
    # shellcheck disable=SC2086
    set $1 # "set" needs this unquoted
    local cols="$#"
    # Convert the matrix
    local IFS=$'\n'
    local n
    for n in $(seq "$cols")
    do
        get-column "$matrix" "$n"
    done
}

## Usage: sqrt number
# Prints an approximate square root of number. Note that this is
# extremely inefficient because it just divides the number by a bunch
# of numbers until it finds a divisor that's at least as large as the
# resulting quotient.
## TODO: Convert to Newton's method or find a standard *nix program
## that includes this.
sqrt() {
    local n="$1"
    local x
    for x in $(seq "$n"); do
        if [[ $((n/x)) -le x ]]; then
            echo "$x"
            dbg "sqrt($n)=$x"
            return
        fi
    done
}

## Usage: process-type type script seperator width
# Generates "magic ratio" columnated word lists of the given type
# (cmavo or gismu), script (dotsies or latin), seperator (tabs or
# spaces recommended), and width (ratio of word+seperator width to
# height, multiplied by 10, and rounded to the nearest whole number).
process-type() {
    local type="$1"
    local script="$2"
    local sep="$3"
    local width="$4"
    #msg "Processing $type for $script script...."
    # Load file
    words="$(cat "$in_dir/$type")"
    # Get magic ratios
    local word_count
    word_count="$(echo "$words" | wc -w)"
    dbg "Found $word_count $type."
    # The "fake" accounts for the width being greater than the height.
    fake_count=$((word_count*width/10))
    # Go far enough that empty columns would appear at the
    # end. Redundant magic numbers will be filtered later.
    stop_at="$((fake_count+$(sqrt "$fake_count")))"
    local results
    msg "Getting magic ratios for {$fake_count..$stop_at}...."
    # shellcheck disable=SC2046
    # The $(seq) expression is meant to be unquoted for magic-ratios().
    results="$(magic-ratios $(seq "$fake_count" "$stop_at"))"
    dbg "Magic ratio numbers found:\n$results"
    msg -n "Processing magic ratios...."
    # Go through magic ratios
    local IFS=$'\n'
    local result
    for result in $results; do
        local IFS=' '
        # shellcheck disable=SC2086
        set $result # "set" needs this unquoted
        local fake_big="$1"
        local small="$2"
        # Check if this result should be filtered (because it's a
        # duplicate of small-1, only with a missing column at the end).
        if [[ $((fake_big*small-small)) -ge fake_count ]]; then
            continue
        fi
        local big=$((fake_big*10/width))
        msg -n " ${big}x${small}..."
        # Make and save the word table
        result="$(echo "$words" | tr ' ' $'\n' | make-columns "$small")"
        result="$(transpose "$result")"
        local out="$out_dir/${type}_${script}_${big}x${small}"
        echo "$result" | tr ' ' "$sep" > "$out"
    done
    echo
}

## Usage: main [min_ratio max_ratio]
# Run process-type with every combination of recommended parameters.
main() {
    if [ "$1" = "help" ]; then
        msg "$usage"
        exit 0
    elif [ "$#" = 2 ]; then
        min_ratio="$1"
        max_ratio="$2"
    elif [ "$#" = 1 ]; then
        min_ratio="$1"
        max_ratio="$1"
    elif [ "$#" != 0 ]; then
        msg "Error: Can only accept up to 2 arguments."
        msg "$usage"
        exit 1
    fi

    in_dir="$(get-data lojban/words -path)" || exit 1
    out_dir="$(get-config "columnate-lojban-words/output-folder" -verbatim -what-do "where the generated Lojban files should be saved")" || exit 1

    # Make sure the output directory exists.
    mkdir -p "$out_dir"
    # Just hard-code the args.... It's simpler than iterating through
    # the predictable ones only to encode a lookup table equivalent.
    process-type cmavo_reduced  dotsies $'\t' 10
    process-type cmavo          latin   $'\t' 40
    process-type gismu          dotsies ' '   10
    process-type gismu          latin   ' '   30
    process-type merged_reduced dotsies $'\t' 10
    process-type merged         latin   $'\t' 40
    msg "\nDone! Here are the generated files, stored in $out_dir."
    ls "$out_dir"
}

main "$@"
