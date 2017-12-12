#!/bin/sh

## PERSONAL CUSTOMIZATIONS

# Add a directory to $PATH iff it exists and isn't already added. Make
# sure to unset this at the end of the script.
__add_to_path() {
    for x in "$@"; do
        if [ -d "$x" ] && ! (echo "$PATH" | grep -Eq "(^|:)$x(:|$)"); then
            export PATH="$PATH:$x"
        fi
    done
}

# Stuff that's not automatically cluttered by programs ($HOME is $H/skami/zdani/DISTRONAME)
H="/home/$USER"
    
# Include private bin folders in PATH
__add_to_path "$H/skami/samtci/bin" "$H/sampla/samselpla/scripts/bin" "$HOME/.cabal/bin"
# Emacs is pretty neat.
EDITOR="emacsclient-t" # Custom commands for running emacsclient
VISUAL="emacsclient-c" # since arguments don't work here.
SUDO_EDITOR="$EDITOR" # Make it work with sudoedit too.
# Enable pretty things like the Zenburn theme in terminal Emacs
TERM="xterm-256color"
# less > more
PAGER="less"

# EXPORT CUSTOM
export H EDITOR VISUAL SUDO_EDITOR TERM PAGER


## GO STUFF

# According to http://golang.org/doc/code.html#GOPATH, GOPATH is "likely the only environment variable you'll need to set when developing Go code".
GOPATH="$H/sampla/samselpla/go"
# However, experience shows that GOBIN is needed to keep it from trying to place binaries in GOROOT.
GOBIN="$H/skami/samtci/bin/go"
# TODO: Figure out why "go build" is placing binaries in the current working directory instead....
# Make sure I can run stuff from GOBIN
__add_to_path "$GOBIN"

# EXPORT GO STUFF
export GOPATH GOBIN


## FIXING PROBLEMS

# Include sbins if not already included (fixes sudo in OpenSUSE)
__add_to_path /sbin /usr/sbin /usr/local/sbin
# Just go to the gorram man page without that annoying prompt, per 
# <https://forums.opensuse.org/showthread.php/427627-The-Man-What-manual-page-do-you-want-prompt?p=2271750#post2271750>
MAN_POSIXLY_CORRECT=1
# KWin says I need this for stuff and references <https://bugs.kde.org/show_bug.cgi?id=322060>.
__GL_YIELD="USLEEP"

## EXPORT PROBLEM FIXES
export MAN_POSIXLY_CORRECT __GL_YIELD


## CLEANUP
unset __add_to_path
