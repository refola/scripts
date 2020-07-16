#!/usr/bin/env bash

# build_bin.sh

# Go through all the scripts and make shortcuts in ./bin, stripping
# the .sh.

# Output control
if [ "$1" = "-v" ]; then
    VERBOSE="true"
fi
## Usage: msg message
# If in verbose mode, call echo with "-e", what's passed, and a
# trailing "\e[0m". Otherwise don't. The "-e" and "\e[0m" are a
# convenience for pretty formatting with colors.
msg () {
    if [ "$VERBOSE" = "true" ]; then
        echo -e "$@" "\e[0m"
    fi
}
msg "\e[32m\$VERBOSE\e[0;1m=\e[32m$VERBOSE"

# Where we are: the place that everything's relative to
here="$(dirname "$(readlink -f "$0")")"
# Be here now, because absolute coordinates are a pain.
cd "$here" || exit 1
msg "\e[92mAt\e[35m $(pwd)"

# Directories to skip, via regex patterns that will be
# concatenated. For example, "\." will skip all items that have a
# literal dot (".") in their name.
##
# Note: This list is hard-coded and not retrieved by get-config
# because this script is uniquely forbidden from having dependencies
# beyond Bash and common *nix utilities.
skip_dirs="
\..*
bash_custom
bin
config
data
example
graveyard
sourced
test
x
zsh_custom
"

# Build the skip pattern by converting newlines to $|^ (separating
# regexes which should match the entire string) and removing the
# outer-most $| and |^ which otherwise remain at the ends.
sep='$|^'
skip_pattern="$(echo -n "$skip_dirs" | sed -z "s/\n/$sep/g" | cut -c${#sep}- | rev | cut -c${#sep}- | rev)"
msg "\e[92mSkipped item regex \e[35m$skip_pattern"

# Where to make the symlinks
bin="./bin"

# Usage: nuke
# Removes everything in $BIN and remakes the directory.
nuke () {
    msg "\e[33mReplacing \e[35m$bin\e[33m with blank folder"
    rm -r "$bin"
    mkdir "$bin"
}

# Usage: target path
# Outputs how the given script should be targetted in a link.
target () {
    local target="$(realpath --no-symlinks --relative-to "$bin" "$1")"
    echo -n "$target"
}

# Usage: name path
# Outputs how a link to the given script path should be named.
name () {
    # The "rev-cut-rev part gets rid of everything after the 4th-last
    # character, e.g., "script.sh" -> "script".
    echo -n "$bin/$(basename "$1" | rev | cut -c4- | rev)"
}

# Usage: process item [depth]
# Recursively adds links to scripts in directory to $here/bin.
process() {
    if [ -d "$1" ]; then # Directory
        if [ -L "$1" ]; then # symlink
            msg "\e[31mSkipping directory symlink \e[35m$1"
        else
            msg "\e[92mAt folder \e[35m$1"
            local item
            for item in "$1"/*; do
                if [ "$(echo -n "$item" | tail -c1)" != "~" ]; then # Skip temporary/backup files from text editors.
                    process "$item"
                fi
            done
        fi
    elif [ -f "$1" ] && [ -x "$1" ]; then # Regular executable file
        local target="$(target "$1")"
        local name="$(name "$1")"
        msg "\e[33mLinking \e[35m$name \e[0;92m-> \e[35m$target"
        ln -s "$target" "$name"
    else # Who knows what this is?
        msg "\e[31mNot processing \e[35m$1"
    fi
}

main() {
    echo -e "\e[33mRebuilding \e[35m$bin....\e[0m"
    if [ -z "$VERBOSE" ]; then
        echo -e "\e[34m(Run this script with '-v' for verbose mode.)\e[0m"
    fi
    nuke
    local item
    for item in *; do
        # If it _doesn't_ match the skip pattern and _is_ a directory
        if echo -n "$item" | grep -qEv "$skip_pattern" && [ -d "$item" ]; then
            process "$item"
        fi
    done
    echo -e "\n\e[33mDone \e[92m^.^\e[0m\n"
}

main
