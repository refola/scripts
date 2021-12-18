# Overview

This folder contains the package manager operations for the `pm`
cross-distro **p**ackage **m**anager front-end. It is hoped that this
system is comprehensive enough to extend pm support to additional
package managers and operations without having to modify `pm`'s code.


# Operations

Each folder corresponds to an operation that pm supports. The symlinks
are for shorcut commands.

For example, `pm up` will check the `up` folder, follow the symlink to
`upgrade`, and then run the commands in `upgrade/$pm` where `$pm` is
the detected package manager name.


# Package manager scope, detection, and precedence

Hypothetically, `pm` could be expanded from a cross-distro basic
package manager into a sort of intelligent
[universal install script](https://www.xkcd.com/1654) with
sane/customizable prioritization and stopping on the first
success. But for now `pm` just chooses one system-level package
manager and acts based on that.

In particular, `pm` chooses the first existing package manager found
in the `pms` file. This file's syntax is simple: Lines starting with
`#` are comments and everything else is a whitespace-separated ordered
list of package manager command names to look for.

For example, even though Arch-like Linuxes can all use `pacman` for
managing packages in the official repositories, `pm` will gladly
prefer an alternative like `paru` if available.


# Package manager commands

Command files are source-able (Bash) shell scripts.

Here's the environment an invoked script will find itself in:

- Package names, if applicable, are set as the positional parameters
  (`"$@"`).
- Several functions are defined by `pm`, some of them useful for
  sourced scripts. Regardless of utility, they cannot be directly used
  as command names. Thus for anything beyond basic \*nix utilities and
  builtins, it's recommended to use the `cmd` function or the
  `command` builtin. As of writing (see `git blame README.md` for the
  latest commit changing this), here's a current list of functions
  which shadow any commands of the same names:
  - `cmd`: `cmd command [args ...]` shows the command (and args) and
    runs it, exiting with error message on failure.
  - `detect`: not for sourced script use
  - `fail`: `fail "reason for failure"` shows the reason and
    immediately exits.
  - `list-pms`: not for sourced script use
  - `msg`: `msg "message to show"` shows a message with some
    formatting to distinguish it as being from `pm` (as opposed to
    being from the underlying package manager).
  - `main`: not for sourced script use
  - `pm-op`: not for sourced script use
  - `scmd`: `scmd command [args ...]` is a shortcut for `cmd sudo
    command [args ...]`.
  - `usage`: not for sourced script use
- Sourcing the script is literally the last thing `pm` does, so
  setting variables/functions/etc can be done freely without concern
  for conflict.

Finally, if correct package action commands are guaranteed to be the
same for a given action with a given set of package managers, then
a symbolic link can be used to avoid duplicating code.


# Checking for shell script syntax pitfalls

For convenience, there's a script called `check-scripts.sh` which runs
`shellcheck` on all the package management action scripts.
