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

## Test cases
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

# Reset config, test abort option, test default config option, test no
# option, and reset config again.
for cfg in "${tests[@]}"
do
    echo -n "$cfg ... "
    val="$(echo -e "${!cfg}")" # Get normalized test case contents
    val_var_rep="$(eval "echo \"$val\"")"
    reset-config "$cfg" "$val"
    test-equal "Abort: $cfg" "$(echo a | get-config "$this/$cfg" 2>/dev/null)" ""
    test-equal "Default: $cfg" "$(echo d | get-config "$this/$cfg" 2>/dev/null)" "$val"
    test-equal "Already set, >&1: $cfg" "$(get-config "$this/$cfg" >&1)" "$val"
    test-equal "Already set: $cfg" "$(get-config "$this/$cfg")" "$val"
    test-equal "Path only: $cfg" "$(get-config "$this/$cfg" -path)" "$config_dir/$cfg"
    test-equal "-var-rep: $cfg" "$(get-config "$this/$cfg" -var-rep)" "$val_var_rep"
    bad_arg_output="$(get-config "$this/$cfg" -bad-arg 2>/dev/null)"
    # 3-stream redirection followed by stderr redirection, as
    # described at http://stackoverflow.com/a/13299397
    bad_arg_errors="$((get-config "$this/$cfg" -bad-arg 3>&2 2>&1 1>&3) 2>/dev/null)"
    bad_arg_result="$?"
    test-equal "No config on bad arg output: $cfg" "$bad_arg_output" ""
    test-true "Non-zero status on bad arg: $cfg" "[ '$bad_arg_result' != '0' ]"
    test-true "Error message on bad arg: $cfg" "[ '$bad_arg_errors' != '' ]"
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
