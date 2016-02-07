#!/bin/bash
#
#  Chakra Mirror-Check - Version 1.90
#  Copyright (c) 2013 - Manuel Tortosa <manutortosa@chakra-project.org>
#  Copyright (c) 2015 - Mark Haferkamp <mark@refola.com>
#
#  This script is licensed under the GPLv3

### GLOBAL VARIABLES ###
_title="Mirror-Check"
# I don't know what the sed command does, but I added the 'tr|sort|tr'
# bit to sort the repos by name.
_repos="$(grep -v "#" < "/etc/pacman.conf" | grep -v "options" | grep "\[" | cut -d[ -f2 | cut -d] -f1 | uniq | sed "{:q;N;s/\n/ /g;t q}" | tr ' ' '\n' | sort | tr '\n' ' ')"
_mode="$1"

### GENERAL FUNCTIONS ###
## Usage: repo_loop function
# Loops thru all repos, running the given function with the repo as an
# argument.
function repo_loop() {
    for repo in $_repos
    do
	      $1 "$repo" &
    done
    wait # ... until all the per-repo function forks have finished
}
## Usage: db_file repo type
# Prints the name of the file for the given repo's database of type
function db_file() {
    echo -n "/tmp/.${UID}_${1}_${2}.tmp"
}

### DATABASE FILE MANAGEMENT FUNCTIONS ###
## Usage: download_or_error url path error
# Downloads the given file to the given path. If there's an error,
# this outputs the given message.
function download_or_error() {
    wget "$1" -O "$2" &> /dev/null
    if [ "$?" != "0" ]
    then
	      echo -n "$3"
    fi
}
## Usage: get_databases repo
# Downloads the main and mirror databases for the given repo. Make
# sure to run delete_databases later to clean up.
function get_databases() {
    local repo="$1"
    local main="http://rsync.chakraos.org/packages/${repo}/x86_64/${repo}.db.tar.gz"
    # Tell shellcheck that the $repo in sed's argument is literal.
    # shellcheck disable=SC2016
    local mirror="$(grep '^[^#]erver' /etc/pacman.d/mirrorlist | head -1 | cut -d' ' -f3 | sed 's,$repo.*,'"${repo}/x86_64/${repo}.db.tar.gz,")"
    for place in main mirror
    do
	      download_or_error "${!place}" "$(db_file "$repo" $place)" "Could not download $place database for $repo. " &
    done
    wait # ... until the wgets finish
}
## Usage: delete_databases repo
# Deletes the main and mirror databases for the given repo
function delete_databases() {
    rm "$(db_file "$1" mirror)" "$(db_file "$1" main)"
}

### SYNCHRONIZATION CHECKING FUNCTIONS ###
## Usage: is_synced repo
# Echos back the repo name iff it is synced.
function is_synced() {
    local main="$(db_file "$1" main)"
    local mirror="$(db_file "$1" mirror)"
    diff "$main" "$mirror" > /dev/null
    if [ "$?" = 0 ]
    then
	      echo "$1"
    fi
}
## Usage: is_synced repo
# Echos back the repo's name iff it's not synced.
function is_unsynced() {
    local synced="$(is_synced "$1")"
    # If is_synced didn't echo it back
    if [ "$synced" != "$1" ]
    then
	      echo "$1"
    fi
}

### CLI FUNCTIONS ###
## Usage: cli_error message
# Displays the given error.
function cli_error() {
    echo -e "\e[00;31mError: $1\e[00m"
}
## Usage: cli_message message
# Displays the given message.
function cli_message() {
    echo -e "\e[01;33m$1\e[00m"
}
## Usage: cli_results synced unsynced
# Outputs which repos are and aren't synced.
function cli_results() {
    for synced in $1
    do
	      echo -e "\e[01;37m[$synced]\e[00m \e[00;32mis synced\e[00m."
    done
    for unsynced in $2
    do
	      echo -e "\e[01;37m[$unsynced]\e[00m \e[00;31mis not synced\e[00m."
    done
}

### GUI FUNCTIONS
## Usage: gui_error error
# Displays the given error.
function gui_error() {
    kdialog --title "${_title}" --error "Error: $1"  &>/dev/null
}
## Usage: gui_message
# Displays the given message.
function gui_message() {
    nohup kdialog --title "${_title}" --msgbox "$1" &>/dev/null &
    __gui_window_pid=$!
}
## Usage: gui_fmt_repos repos fmt
# Formats list lines of repos for the GUI.
function gui_fmt_repos() {
    local fmt="$2"
    for repo in $1
    do
	      # Tell shellcheck that we really want $fmt in printf's format string.
	      # shellcheck disable=SC2059
	      printf "<li>$fmt</li>" "$repo"
    done
}
## Usage: gui_results synced unsynced
# Shows a message of which repos are and aren't synced.
function gui_results() {
    local synced_fmt="<b>[%s]</b> is <font color=\"#00FF00\">synced</font>."
    local unsynced_fmt="<b>[%s]</b> is <font color=\"#FF0000\">not synced</font>."
    local text="<ul>"
    text="$(gui_fmt_repos "$1" "$synced_fmt")"
    text="$text$(gui_fmt_repos "$2" "$unsynced_fmt")"
    text="$text</ul>"
    gui_message "$text"
}
## Usage: gui_close_window
# Closes any open GUI windows.
function gui_close_window() {
    kill $__gui_window_pid
    wait $__gui_window_pid &> /dev/null
}

## Usage: usage
# Prints the mirror-check help/usage message.
function usage() {
    echo "${_title}"
    echo
    echo "Usage: mirror-check [flag]"
    echo
    echo "Flags:"
    echo "--cli   Command Line Interface mode (default)"
    echo "--gui   KDialog GUI"
    echo "--help  This message"
    echo
}

## Usage: runit error_function message_function results_function
# Runs the script with the given gui or cli functions, as follows.
# * error_function: show the user a given error message
# * message_function: show the user a message
# * results_function: display the results
# * close_window_function: close open windows as applicable
function runit() {
    local error_fn="$1"
    local msg_fn="$2"
    local result_fn="$3"
    local close_fn="$4"
    if [ ! -f "/etc/pacman.conf" ]
    then
	      $error_fn "Could not find '/etc/pacman.conf'. Are you sure you're running a pacman-based distro?"
	      exit 1
    fi
    $msg_fn "Checking $_repos..."
    local error="$(repo_loop get_databases)"
    $close_fn
    if [ ! -z "$error" ]
    then
	      $error_fn "$error"
	      exit 1
    fi
    local synced="$(repo_loop is_synced | sort)"
    local unsynced="$(repo_loop is_unsynced | sort)"
    repo_loop delete_databases
    $result_fn "$synced" "$unsynced"
}

## Usage: main
# Gets command line arguments and runs the appropriate action.
function main() {
    if [ "${_mode}" == "--help" ]
    then
	      usage
    elif [ "${_mode}" == "--gui" ]
    then
	      runit gui_error gui_message gui_results gui_close_window
    else
	      runit cli_error cli_message cli_results true # "true" is a no-op replacement for closing a cli window
    fi
}

main
