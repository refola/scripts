#!/bin/bash
## get-config-test.sh
# Test the get-config script.

# Sanity check
which dirname get-config cmpath >/dev/null || exit 1

# Shortcut variable for config names
this="get-config-test"

# Config locations
# Assumes this is in "test" which is a sibling of "config"
defaults_dir="$(dirname "$(cmpath "$0")")/../config/$this"
# Yes, the config location is hard-coded instead of configured.
config_dir="$HOME/.config/refola/scripts/$this"

# Test results
num_tests="0"
num_pass="0"
num_fail="0"

# Color functions
green() { echo -n "\e[0;32m${1}\e[0m"; }
red() { echo -n "\e[0;31m${1}\e[0m"; }
yellow() { echo -n "\e[1;33m${1}\e[0m"; }

## Usage: show-result description result
# Shows the result iff the description is non-empty.
show-result() {
    if [ -n "$1" ]
    then
	echo -e "$1: $2"
    fi
}

# Shows the overall results of the tests.
show-results() {
    echo -e "Pass: $(green "$num_pass")/$num_tests"
    echo -e "Fail: $(red "$num_fail")/$num_tests"
}

## Usage: test-true description predicate
# Increments $num_tests, tests if the predicate is true, outputs the
# result if description is of nonzero length, and increments either
# $num_pass or $num_fail as appropriate.
## Note that predicate must be valid for eval and its truth is
## determined by its exit code. For example, '[ "abc" = "xyz" ]' is a
## valid predicate, as is any command (optionally with arguments) that
## returns true or false.
test-true() {
    local desc="$1"
    local pred="$2"
    ((num_tests++))
    if eval "$pred"
    then
	#show-result "$desc" "$(green Pass)"
	((num_pass++))
	return 0
    else
	show-result "$desc" "$(red Fail)" # - $(yellow "$pred") is false."
	((num_fail++))
	return 1
    fi
}

## Usage: test-equal description string1 string2
# Use test-true to check if two strings are equal.
test-equal() {
    if ! test-true "$1" "[ '$2' = '$3' ]"
    then
	echo "'$2' not equal to '$3'"
	echo
    fi
}

## Usage: reset-config config-name [value]
# Deletes the live config-name and optionally sets the default to the
# given value, using escape codes.
reset-config() {
    local name="$1"
    local value="$2"
    if [ -f "$config_dir/$name" ]
    then
	rm "$config_dir/$name"
    fi
    if [ -n "$value" ]
    then
	echo -e "$value" > "$defaults_dir/$name"
    fi
}

# Config variables
# shellcheck disable=SC2034
foo="one-word_config"
# shellcheck disable=SC2034
bar="one-line config with spaces"
# shellcheck disable=SC2034
baz="multi\nline\nconfig"
# shellcheck disable=SC2034
quux="s p a c e s\nt\ta\tb\ts\nand newlines"
tests=(foo bar baz quux)

echo "Testing $this...."

# Reset config, test abort option, test default config option, test no
# option, and reset config again.
for cfg in "${tests[@]}"
do
    val="$(echo -e "${!cfg}")" # Get normalized test case contents
    reset-config "$cfg" "$val"
    test-equal "Abort: $cfg" "$(echo a | get-config "$this/$cfg" 2>/dev/null)" ""
    test-equal "Default: $cfg" "$(echo d | get-config "$this/$cfg" 2>/dev/null)" "$val"
    test-equal "Already set, >&1: $cfg" "$(get-config "$this/$cfg" >&1)" "$val"
    test-equal "Already set: $cfg" "$(get-config "$this/$cfg")" "$val"
    reset-config "$cfg" "$val"
done

rmdir "$config_dir"

show-results
if [ ! "$num_pass" = "$num_tests" ]
then
    exit 1
fi
