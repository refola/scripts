#!/bin/bash

## PERSONAL CUSTOMIZATIONS

# Add a directory to $PATH iff it exists and isn't already added. Make
# sure to unset this at the end of the script.
__refola_add_path() {
    for x in "$@"; do
        if [ -d "$1" ] && ! (echo "$PATH" | grep -q "$1"); then
            PATH="$PATH:$1"
        fi
    done
}

# Stuff that's not automatically cluttered by programs ($HOME is $H/sys/DISTRONAME)
H="/home/$USER"
    
# Include private bin folders in PATH
__refola_add_path "$H/skami/samtci/bin" "$H/sampla/samselpla/scripts/bin" "$HOME/.cabal/bin"
# Emacs is pretty neat.
EDITOR="emacsclient-t" # Custom commands for running emacsclient
VISUAL="emacsclient-c" # since arguments don't work here.
# Enable pretty things like the Zenburn theme in terminal Emacs
TERM="xterm-256color"
# less > more
PAGER="less"

# EXPORT CUSTOM
export H PATH EDITOR VISUAL TERM PAGER


## GO STUFF

# According to http://golang.org/doc/code.html#GOPATH, GOPATH is "likely the only environment variable you'll need to set when developing Go code".
GOPATH="$H/sampla/samselpla/go"
# However, experience shows that GOBIN is needed to keep it from trying to place binaries in GOROOT.
GOBIN="$H/skami/samtci/bin/go"
# TODO: Figure out why "go build" is placing binaries in the current working directory instead....
# Make sure I can run stuff from GOBIN
__refola_add_path "$GOBIN"
# Shortcut variables for common paths
GOREF="$GOPATH/src/github.com/refola"

# EXPORT GO STUFF
export GOPATH GOBIN PATH GOREF


## FIXING PROBLEMS

# Include sbins if not already included (fixes sudo in OpenSUSE)
__refola_add_path /sbin /usr/sbin /usr/local/sbin
# Just go to the gorram man page without that annoying prompt, per 
# <https://forums.opensuse.org/showthread.php/427627-The-Man-What-manual-page-do-you-want-prompt?p=2271750#post2271750>
MAN_POSIXLY_CORRECT=1
# KWin says I need this for stuff and references <https://bugs.kde.org/show_bug.cgi?id=322060>.
__GL_YIELD="USLEEP"

## EXPORT PROBLEM FIXES
export PATH MAN_POSIXLY_CORRECT __GL_YIELD


## CLEANUP
unset __refola_add_path
