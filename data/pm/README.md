# Overview

This folder contains the package manager operations for the `pm`
multi-distro package manager front-end. It is hoped that this system
is comprehensive enough to extend pm support to additional package
managers and operations without having to modify `pm`'s code.


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
in the `pms` file. This file is a whitespace-separated manually sorted
list of package manager command names. Prioritization is currently
done by using a "high priority" list, a line, and then a "low
priority" list.

For example, even though Chakra Linux has the `pacman` command, `pm`
will run operations on Chakra via the `chaser` files instead.


# Package manager commands

Command files are source-able (Bash) shell scripts.

Here are the key environment details the script will find itself in:

- The package names are set as the positional parameters (`"$@"`).
- `cmd command [args ...]` will show the user what command is being
  ran and then run it, exiting with error message on failure.
- `scmd command [args ...]` is a shortcut for `cmd sudo command
  [args ...]`.
- `fail "reason for failure"` will show the reason and immediately
  exit.
- These functions are defined by `pm` and cannot be directly used as
  command names: `cmd, detect, fail, msg, main, pm-op, scmd`. If a
  package manager uses a command with any of these names, it's
  recommended to use the `cmd` function or the `command` shell
  builtin.
- Sourcing the script is literally the last thing `pm` does, so
  setting variables/functions/etc can be done freely without concern
  for conflict.

Finally, if correct package action commands are guaranteed to be the
same for a given action with a given set of package managers, then
a symbolic link can be used to avoid duplicating code.


# Checking for shell script syntax pitfalls

For convenience, there's a script called `check-scripts.sh` which runs
`shellcheck` on all the package management action scripts.
