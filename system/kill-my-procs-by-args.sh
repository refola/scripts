#!/usr/bin/env bash
## system/kill-my-procs-by-name.sh
# Kill current user's processes by name.

usage="Usage: $0 'enough of contiguous command name and/or args' [...]

Kills invoking user's processes by name and arguments, as a
more-general and more-dangerous variant of the idea behind the
standard 'killall' command. In particular so scripts can kill scripts.

See 'Example' below for how this differs from the standard 'killall'
command. Also see 'Warning' below that for how this could cause
unexpected damage.

Example: If you run 'update-grub', then the actual command arguments
might be '/bin/sh -e /usr/sbin/update-grub'. This would be caused by
the 'update-grub' command being found under '/usr/sbin/' and starting
with the \"shebang\" line '#!/bin/sh -e'. This would cause 'killall
update-grub' to fail due to the actual process name being
'sh'. Furthermore, because there could be several other scripts
running under the 'sh' interpreter, running 'killall sh' would kill
too much. However, because 'update-grub' is in the arguments passed to
'sh' when it's ran, searching by full command name + args may yield
the desired result.

Warning: Even though this is more accurate than 'killall' for killing
interpreted scripts by invoked name, this can easily kill too much if
you happen to be running, e.g., a text editor that's editing the
script you're killing the processes of. This problem can be reduced by
including the interpretor's name, but such a solution is then fragile
against program updates changing their interpretors.

"

if [ -z "$1" ]; then
    echo -e "$usage"
    exit 1
fi

IFS=$'\n'
for name in "$@"; do
    # TODO: Why doesn't $BASHPID work directly?!‽
    ## 'pgrep' is no substitute for grepping thru ps output for args
    # shellcheck disable=SC2009
    for line in $(bp=$BASHPID; ps xo pid=,args= | grep "$name" |
                      grep -v "grep $name" | grep -Ev " *($bp|$$) "); do
        pid="$(echo "$line" | sed -r 's/\s*([0-9]+) .*/\1/g')"
        kill "$pid"
    done
done
