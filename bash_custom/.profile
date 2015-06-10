#!/bin/bash

## CUSTOM STUFF

# Stuff that's not automatically cluttered by programs ($HOME is $H/sys/DISTRONAME)
H="/home/$USER"
# Include private bin folders in PATH
PATH="$H/prog/bin:$PATH"
PATH="$H/prog/script/bin:$PATH"
PATH="$HOME/.cabal/bin:$PATH"
# Emacs is pretty neat.
EDITOR="emacsclient-t" # Custom commands for running emacsclient
VISUAL="emacsclient-c" # since arguments don't work here.
# Enable pretty things like the Zenburn theme in terminal Emacs
TERM="xterm-256color"

# EXPORT CUSTOM
export H PATH EDITOR VISUAL TERM


## GO STUFF

# According to http://golang.org/doc/code.html#GOPATH, GOPATH is "likely the only environment variable you'll need to set when developing Go code".
GOPATH="$H/code/go"
# However, experience shows that GOBIN is needed to keep it from trying to place binaries in GOROOT.
GOBIN="$H/prog/bin/go"
# TODO: Figure out why "go build" is placing binaries in the current working directory instead....
# Make sure I can run stuff from GOBIN
PATH="$GOBIN:$PATH"
# Shortcut variables for common paths
GOREF="$H/code/go/src/github.com/refola"

# EXPORT GO STUFF
export GOPATH GOBIN PATH GOREF


## FIXING PROBLEMS

# Include sbins (fixes sudo in OpenSUSE)
PATH="$PATH:/sbin:/usr/sbin:/usr/local/sbin"
# Just go to the gorram man page without that annoying prompt, per 
# <https://forums.opensuse.org/showthread.php/427627-The-Man-What-manual-page-do-you-want-prompt?p=2271750#post2271750>
MAN_POSIXLY_CORRECT=1
# KWin says I need this for stuff and references <https://bugs.kde.org/show_bug.cgi?id=322060>.
__GL_YIELD="USLEEP"

## EXPORT PROBLEM FIXES
export PATH MAN_POSIXLY_CORRECT __GL_YIELD
