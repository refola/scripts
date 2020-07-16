#!/usr/bin/env bash
## hanacron.sh

bold() {
    echo -e "\e[1m$*\e[0m"
}

usage="hanacron [cmd] [args ...]

Human Anacron is a reminder program that handles the storage and time
calculation aspects of scheduling tasks for the human user. This is
like the 'anacron' program, but requires the user to run it manually
to retrieve tasks.

Commands and their arguments follow. Note that any references to time
are the same as understood by the 'date --date=' command, with the
added aliases of 'zero' for '0000-01-01T00:00:00' (the start of '0AD')
and 'infinity' for '1000000000 years hence' (one billion years from
now).


$(bold complete) id [...] 

Mark the task(s) of the given id(s) as having been complete. Ids are
shown on task creation and are also shown using the 'list'
command. There are also special ids as follows.

all
   Matches all tasks

past
   Matches all tasks which are past their due time.


$(bold help)
   Show this usage information and exit.


$(bold list) [args ...]

List tasks. By default hanacron lists all undone tasks with due dates
up to a user-configured time in the future (default: $(get-default
lookahead)).

Args are as follows:

--all
   Equivalent to '--start zero --end infinity --show-complete'.

--end time
   Only show events next scheduled for at or before the given time.

--show-complete
   Also show complete events.

--start time
   Only show events next scheduled for at or after the given time.


$(bold set) time description [...]

Set a new task of given description and at the given time. As a
convenience, the description may optionally use multiple args, which
are then concatenated and space-separated."

echo "$usage"

## systemd service setup
# Place files in `~/.config/systemd/user/` and run `systemctl --user`
# for applicable commands. Otherwise just mirror `backup-btrfs`
# stuff. See [https://wiki.archlinux.org/index.php/Systemd/User] for
# more info.
