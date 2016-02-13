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

## Usage: color name code
# Makes a color-setting function of given name, using given code
color ()
{
    local name="$1";
    local code="$2";
    local template='%s() { echo -n "\\e[%sm$*\\e[0m"; }';
    # Using "$template" as the printf format string intentional.
    # shellcheck disable=SC2059
    local command="$(printf "$template" "$name" "$code")";
    eval "$command"
}
# Set color functions
color green  "0;32"
color red    "0;31"
color yellow "1;33"

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
        show-result "$desc" "$(red Fail): $(yellow "$pred") is false."
        ((num_fail++))
        return 1
    fi
}

## Usage: test-equal description string1 string2
# Use test-true to check if two strings are equal.
test-equal() {
    test-true "$1" "[ '$2' = '$3' ]"
}

## Usage: reset-config config-name [value]
# Deletes the live config-name and optionally sets the default to the
# given value, using escape codes.
reset-config() {
    local name="$1"
    local value="$2"
    if [ -f "$config_dir/$name" ]; then
        rm "$config_dir/$name"
    fi
    if [ -n "$value" ]; then
        mkdir -p "$defaults_dir"
        echo "$value" > "$defaults_dir/$name"
    elif [ -f "$defaults_dir/$name" ]; then
        rm "$defaults_dir/$name"
    fi
}

## Situations to test (the shellcheck disables are for "unused variable")
# shellcheck disable=SC2034
test_simple="one-word_config"
# shellcheck disable=SC2034
test_spaces="one-line config with spaces"
# shellcheck disable=SC2034
test_lines="multi\nline\nconfig"
# shellcheck disable=SC2034
test_mixed_separators="s p a c e s\nt\ta\tb\ts\nand newlines"
# shellcheck disable=SC2034
test_var_rep_one_line="\$H/foo/bar"
# shellcheck disable=SC2034
test_var_rep_multi_line="host=\"\$HOSTNAME\"\nhome=\"\$HOME\"\nroot=\"/\""

## List of test case variables
tests=(test_simple test_spaces test_lines test_mixed_separators
       test_var_rep_one_line test_var_rep_multi_line)

echo -n "Testing get-config with: "

# Reset config, test a bunch of situations, and remove config.
for cfg in "${tests[@]}"
do
    # Utility function to abbreviate tests.
    get() { get-config "$this/$cfg" "$@"; }
    
    # Show some context
    echo -n "$cfg ... "

    # What the configs should be
    raw="$(echo -e "${!cfg}")"       # Verbatim test case contents
    evald="$(eval "echo \"$raw\"")"  # Test case with ${variable}-expression replacements
    path="$config_dir/$cfg"

    # Set config to have default
    reset-config "$cfg" "$raw"

    # Test basic cases without extra arguments
    test-equal "Abort: $cfg" "$(echo a | get 2>/dev/null)" ""
    $(echo a | get 2>/dev/null)
    exit_code=$?
    test-true "Abort gives non-zero exit code: $cfg" "[ '$exit_code' != '0' ]"
    test-equal "Default: $cfg" "$(echo d | get 2>/dev/null)" "$evald"
    test-equal "Already set, >&1: $cfg" "$(get >&1)" "$evald"
    test-equal "Already set: $cfg" "$(get)" "$evald"

    # Test valid arguments
    test-equal "-path: $cfg" "$(get -path)" "$path"
    test-equal "-var-rep: $cfg" "$(get -var-rep)" "$evald"
    test-equal "-var-rep does nothing: $cfg" "$(get -var-rep)" "$(get)"
    test-equal "-verbatim is verbatim: $cfg" "$(get -verbatim)" "$raw"

    # Test invalid arguments
    bad_arg_output="$(get -bad-arg 2>/dev/null)"
    # 3-stream redirection followed by stderr redirection, as
    # described at http://stackoverflow.com/a/13299397
    bad_arg_errors="$( (get -bad-arg 3>&2 2>&1 1>&3) 2>/dev/null)"
    bad_arg_result="$?"
    test-equal "No config on bad arg output: $cfg" "$bad_arg_output" ""
    test-true "Non-zero status on bad arg: $cfg" "[ '$bad_arg_result' != '0' ]"
    test-true "Error message on bad arg: $cfg" "[ '$bad_arg_errors' != '' ]"

    # Remove test configuratios
    reset-config "$cfg"
done
echo

# cleanup
rmdir "$config_dir"
rmdir "$defaults_dir"

show-results
if [ ! "$num_pass" = "$num_tests" ]
then
    exit 1
fi
