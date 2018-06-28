# Overview

This folder contains the package manager operations for the `pm`
multi-distro package manager front-end. It is hoped that this system
is comprehensive enough to extend pm support to additional package
managers and operations without having to modify `pm`'s code.


# Operations

Each folder corresponds to an operation that pm supports. The symlinks
are for shorcut commands.

For example, `pm up` will check `up`, find that it's a symlink
pointing to `upgrade`, and then run the commands in `upgrade/$pm`
where `$pm` is the detected package manager name.


# Use of `sudo`

## Determining which package manager to use `sudo` with

The `sudo-pms` and `non-sudo-pms` files respectively list the package
managers for `pm` to support with and without `sudo`. Most package
managers need to be ran with `sudo` explicitly, though some have that
functionality built-in, like how `pm` works. These files tell `pm`
which package manager is which of which type.

For example, `ccr` is in the `non-sudo-pms` file, so `pm` will not
prefix any `ccr` commands with `sudo`. However, `pacman` is in the
`sudo-pms` file, so `pm` will run system-changing `pacman` commands
with `sudo`.

## Avoiding `sudo` based on the operation

Normally, `pm` will determine based on the name of a command whether
or not it should prefix a command's invocation with `sudo`. However,
if an operation folder contains a `.no-sudo` file, then the commands
for that operation are guaranteed not to use `sudo`, even if they
otherwise would.

For example, the `search` folder contains a `.no-sudo` file, so `pm
search pkg-name` will not use `sudo`, even if it runs a command like
`pacman` or `apt-get` that's usually used with `sudo`.


# Package manager precedence

Eventually `pm` might add support for running several package managers
in a single operation, e.g., for the plethora of language-specific
user package systems. But for now `pm` just chooses one system-level
package manager and runs that.

In particular, `pm` chooses the first package manager found in the
`non-sudo-pms` file, or, failing that, the first in `sudo-pms`. This
precedence is justified by the author's experience of all encountered
system-level package managers that have their own `sudo` invocation
being the user's/system's prefered package manager.

For example, even though Chakra Linux has the `pacman` command, `pm`
will run operations on Chakra via the commands found in `ccr` ("Chakra
Community Repository") files instead.

Note that this still works even for operations not supported by `pm`'s
chosen package manager, since `pm` just runs a list of commands in a
file named after the package manager it's nominally using.

For example, the `info/ccr` file contains `pacman -Qi $args`, since
the `ccr` front-end doesn't support querying package info, but
`pacman` does.


# Package manager commands

Within each operation folder are several files named after the package
managers that `pm` runs. If `pm` is invoked with operation `$op` and
finds package manager `$pm`, then `pm` will run the commands found in
the file at `$op/$pm`.

In order to allow per-package-manager control over how `pm`'s
arguments are handled, the variable `$args` in a command will be
replaced with any arguments that `pm` was passed after its
operation. For example, if `pm` is ran with `pm in shiny-package` and
detects that your system's package manager is `ccr`, then it will read
the file at `in/ccr`, find that it contains `ccr -S $args`, and then
run `ccr -S shiny-package`.
