#!/usr/bin/env python3

"""
backup-btrfs2.py
Modified: 2019-04-19
Run btrfs backups via (incremental) snapshots.

This script snapshots btrfs subvolumes and (incrementally) clones them
to other drives.

Please check out this link for underlying btrfs commands used and
alternative btrfs backup scripts (which are probably more-advanced and
useful than this one):
https://btrfs.wiki.kernel.org/index.php/Incremental_Backup


=== contents ===

comments:
- header
-- shebang
-- short description
-- note
- contents
-- comments
-- code
- limitations
-- recentism
-- time quantization
- filesystem layout
-- subvolume locations
-- snapshot name format
-- backup snapshot clone structure
-- example

code:
- global variable declarations
-- debug mode
-- exit traps
-- start time timestamp
-- config explanation
-- install parameters
-- usage
- generic utility functions
-- exit traps
-- messages
-- command-running
-- path existence checking
-- list formatting
-- presence in list checking
- btrfs utility functions
-- last backup name retrieval
-- subvolume path-to-name sanitization
- btrfs actions
-- snapshot creation
-- snapshot clone/update
-- old snapshot deletion
- high-level snapshot actions
-- subvolume-looping function
-- snapshot creation
-- snapshot clone/update
-- old snapshot deletion
- initial checks and setup
-- initialization
- main stuff
-- configuration getting
-- configuration checking
-- configuration running
-- systemd service installation
-- systemd service reinstallation
-- systemd service uninstallation
-- usage information
-- main


=== limitations ===

This script assumes that you mostly just want the latest data. It does
not backup older snapshots.

This script uses 1-second time granularity, so new snapshots are
'always' made (the exception being if this script on somehow finishes
in under a second on your system).


=== filesystem layout ===

The original subvolumes can be anywhere under the respective btrfs root.

Snapshots are stored within the btrfs root in folders named after the
subvolumes, with '@' converted to '-' so nested subvolumes work
correctly (assuming you're not using '-' in your subvolume names in a
conflicting way). Within a subvolume's snapshot folder are the actual
snapshots, which are named by the ISO-8601-formatted UTC time of
script invocation, to 1-second precision, as given by the command
'date --utc --iso-8601=seconds'.

On backup filesystems, snapshots are cloned with the same structure as
the snapshots directory.

Example: Suppose you have subvolumes @distro, @home, and @home/user in
your main btrfs volume mounted at /root; you want to store snapshots
under @snapshots; and you want to backup snapshots to /backup. Then
the layout will look something like this, with more timestamped
snapshots appearing over time:

Original subvolume paths:
- /root/@distro
- /root/@home
- /root/@home/user

Snapshot paths (assuming you ran this script at the respective times):
- /root/@snapshots/@distro/2016-03-31T16:43:13+00:00
- /root/@snapshots/@distro/2016-04-17T23:53:47+00:00
- /root/@snapshots/@distro/2016-04-18T01:24:20+00:00
- /root/@snapshots/@home/2016-03-31T16:43:13+00:00
- /root/@snapshots/@home/2016-04-17T23:53:47+00:00
- /root/@snapshots/@home/2016-04-18T01:24:20+00:00
- /root/@snapshots/@home-user/2016-03-31T16:43:13+00:00
- /root/@snapshots/@home-user/2016-04-17T23:53:47+00:00
- /root/@snapshots/@home-user/2016-04-18T01:24:20+00:00

Backup paths (assuming the backup drive wasn't available when the
2016-04-17 snapshots were made):
- /backup/@distro/2016-03-31T16:43:13+00:00
- /backup/@distro/2016-04-18T01:24:20+00:00
- /backup/@home/2016-03-31T16:43:13+00:00
- /backup/@home/2016-04-18T01:24:20+00:00
- /backup/@home-user/2016-03-31T16:43:13+00:00
- /backup/@home-user/2016-04-18T01:24:20+00:00

"""

from sh import sudo
from os import listdir
from os.path import basename, join, lexists
from sys import argv, exit
import datetime

print("WARNING: Not ready for testing.")
exit(1)

# === global variable declarations ===

# Set by main(): must have usable defaults or installed version breaks
DEBUG = False  # Disabled (True for enabled, or run with DEBUG)

"""
How much info should be shown:
-2: `fatal`
-1: `fatal`, `msg`
 0: `fatal`, `msg`, `cmd` goals
+1: `fatal`, `msg`, `cmd` goals, `cmd` commands
+2: `fatal`, `msg`, `cmd` goals, `cmd` commands, `cmd` outputs
+3: `fatal`, `msg`, `cmd` goals, `cmd` commands, `cmd` outputs, `dbg`
"""
VERBOSITY = 0  # default

# Set near run-exit-traps()
EXIT_TRAPS = []

# Set by init()
LOCKDIR = None
TIMESTAMP = None  # invocation time, used as "latest snapshot time"

# Set near check-config()
CONFIG_USE = None

# Set near install()
INSTALL_PATH = None
SYSTEMD_TARGET = None
AUTOGEN_MSG = None

# Set near usage()
USAGE = None


# === generic utility functions ===

# list of commands to run on exit
EXIT_TRAPS = []


# # TODO: Usage: trap run-exit-traps EXIT
# Run everything in EXIT_TRAPS.
def run_exit_traps():
    for f in EXIT_TRAPS:
        # TODO: msg "Running exit trap: $i"
        f()
# TODO: trap run-exit-traps EXIT # Might only work on Linux+Bash.


# # Usage: add_exit_trap(function1[, function2[, ...]])
# Adds given function(s) to the list of things to run on script exit.
def add_exit_trap(*args):
    global EXIT_TRAPS
    EXIT_TRAPS += args


# # Usage: fatal(error)
# Formats the given error message, outputs it to stderr, and exits the
# script.
##
# VERBOSITY: any
def fatal(error, code=1):
    # TODO: '\e[31mError:\e[0;1m $*\e[0m' formatting
    # TODO: >&2 redirection
    print("Error: " + error)
    exit(code)


# # Usage: msg(text)
# Outputs a message with a bit of formatting. This should be used
# instead of echo almost everywhere in this script.
##
# VERBOSITY: -1
def msg(text):
    # TODO: "\e[1m$*\e[0m" formatting
    VERBOSITY <= -1 or print(text)


# # Usage: cmd(goal, command [args ...]
# Normal function: Displays goal and runs given external command (with
# given args as applicable). Exits script on error.
##
# In debug mode: Displays goal and shows command that would have been
# attempted.
##
# Note: Every simple system-changing command in this script should be
# ran via cmd. Use 'cmd-eval' if you need shell features like unix
# pipes.
##
# TODO: This should be merged with cmd-eval, but that seems to require
# a sophisticated string-escaping function to convert this one's
# variadicness into an eval'able string.
##
# VERBOSITY: 0 (goals), 1 (commands), 2 (outputs)
def cmd(goal, cmd, *args):
    VERBOSITY >= 0 and msg("Doing task: %s." % goal)
    # TODO: '\e[33m' formatting
    VERBOSITY >= 1 and msg("sudo %s %s" % (cmd, ' '.join(args)))
    if not DEBUG:
        if VERBOSITY >= 2:
            print(sudo(cmd, *args))
        else:
            sudo(cmd, *args)
        # TODO: sh->py: try/catch
        # fatal("Could not %s." % goal)


# # Usage: cmd_eval(goal, "string to evaluate")
# Normal function: Displays goal and evals given string. Exits script
# on error.
##
# In debug mode: Displays goald and shows code that would have been
# eval'd.
##
# This is the less-automatic variant of 'cmd', intended for cases
# where things like unix pipes are required.
##
# NOTE: You need to manually add "sudo" to commands ran with
# this. Thus this is also good for non-root commands.
##
# VERBOSITY: 0 (goals), 1 (commands), 2 (outputs)
def cmd_eval(goal, str2eval):
    VERBOSITY >= 0 and msg("Doing task: %s." % goal)
    # TODO: '\e[33m' fmt
    VERBOSITY >= 1 and msg(str2eval)
    if not DEBUG:
        if VERBOSITY >= 2:
            eval(str2eval) or fatal("Could not %s." % goal)
        else:
            # TODO: suppress output
            eval(str2eval) or fatal("Could not %s." % goal)


# # Usage: dbg(messages[, ...])
# Outputs a message with a bit of formatting. This should be used
# instead of echo for showing internal state for debugging.
##
# VERBOSITY: 3
def dbg(*msgs):
    # TODO: "\e[33m" formatting
    VERBOSITY < 3 or print(' '.join(msgs))


# # Usage: exists(path[, ...])
# Check if given paths exist, giving a message and returning 1 on
# first non-existent path. Useful for, e.g., "if exists
# /path/to/place; then do-thing; fi".
def exists(*paths):
    for p in paths:
        if not lexists(p):
            msg("Not found: "+p)
            return False
    return True


# # Usage: list(items, sep=', ', last=', and')
# Lists all the items, separating them with the given separator,
# switching to last for separating the last pair.
# # Example:
# my_list=list('a', 'b', 'c')
# print(my_list) # "a, b, and c"
def list(items, sep=', ', last=', and'):
    return last.join(sep.join(items[:-2]), items[-1])


# === btrfs utility functions ===

# # Usage: last_backup_name=last_backup(backup_dirs)
# Get name of last backup found in all given backup directories, or
# empty string if they have no backup in common.
##
# NOTE: This assumes that this script is the only source of items in
# the snapshot directory.
def last_backup(dirs):
    # Go thru all snapshots in first directory, in reverse order
    # (newest first).
    for snap in sorted(listdir(dirs[0]), reverse=True):
        # Get just the snapshot's name without containing directory.
        snap = basename(snap)
        for dir in dirs[1:]:
            if not lexists(join(dir, snap)):
                # Give up on current backup name at first failure.
                break
        else:  # This else executes iff the preceding loop completed.
            # The first (newest) success is correct.
            return snap
    return None  # Failed to find common snapshot


# # Usage: sanitize(subvol)
# Sanitize given subvolume name by turning each '/' into a '-'.
##
# BUG: This doesn't distinguish between, e.g., "my-subvol" and
# "my/subvol".
def sanitize(subvol):
    return subvol.replace('/', '-')


# === btrfs actions ===

# # Usage: snapshot(from_root, to_snapshot_dir, subvol)
# Snapshots from-root/subvol to to-snapshot-dir/subvol/$TIMESTAMP
# (sanitizing subvol and making the directory for the to-snapshot-dir
# side, as applicable) and runs 'sync' to workaround a bug in btrfs.
def snapshot(from_root, to_snap_dir, subvol):
    sanSv = sanitize(subvol) or fatal("WTF? (sanitize %s)" % subvol)
    target = join(to_snap_dir, sanSv)
    fro = join(from_root, subvol)
    to = join(target, TIMESTAMP)
    if not lexists(target):  # Make sure target directory exists.
        cmd("make snap target directory '%s'" % target,
            "mkdir", "-p", target)
    cmd("snapshot '%s' to '%s'" % (fro, to),
        'btrfs', 'subvolume', 'snapshot', '-r', fro, to)
    # TODO: Remove 'sync' when cloning stops requiring it after
    # snapshots. See
    # https://btrfs.wiki.kernel.org/index.php/Incremental_Backup#Initial_Bootstrapping
    cmd_eval("'sync' so 'btrfs send' works later", 'sync')  # TODO: sh->py


# # Usage: clone_or_update(fro, to, subvolume)
# Use btrfs commands to make it so that to/sanitized-subvolume
# contains a copy of the latest btrfs subvolume at
# from/sanitized-subvolume.
##
# Result: to/sanitized-subvolume/latest-snapshot-date matches
# from/sanitized-subvolume/latest-snapshot-date.
def clone_or_update(fro, to, subvol):
    sv = sanitize(subvol)
    last = last_backup(join(fro, sv))
    if last is None:
        fatal("Could not get last backup in '%s'." % join(fro, sv))
    if not exists(join(to, sv)):  # Make sure target directory exists.
        cmd("make clone target directory '%s'" % join(to, sv),
            'mkdir', '-p', join(to, sv))
    parent = last_backup(join(to, sv), join(fro, sv))
    dbg("clone_or_update: fro='%s' to='%s' subvol='%s'" % (fro, to, subvol))
    dbg("                 sv='%s' last='%s' parent='%s'" % (sv, last, parent))

    if parent is None:  # No subvols found, so bootstrap.
        # TODO: sh->py
        cmd_eval("clone snapshot '%s' from '%s' to '%s'" %
                 (join(sv, last), fro, to),
                 "sudo btrfs send --quiet '$from/$sv/$last' | " +
                 "sudo btrfs receive '$to/$sv'")
    elif exists(join(to, sv, last)):  # Nothing to do.
        msg("Skipping '%s' because '%s' already has the latest snapshot " +
            "'%s' from '%s'." %
            (subvol, to, join(sv, last), fro))
    else:  # Incremental backup.
        # TODO: sh->py
        cmd_eval("clone snapshot '%s' from '%s' to '%s' via parent '%s'" %
                 (join(sv, last), fro, to, join(sv, parent)),
                 "sudo btrfs send --quiet -p '%s' " % join(fro, sv, parent) +
                 "'%s' | sudo btrfs receive '%s'" %
                 (join(fro, sv, last), join(to, sv)))


# # Usage: delete_older_than(location, time, min_keep_count, subvolume)
# Deletes btrfs snapshots for 'subvolume' at 'location' that are older
# than 'time', keeping at least the latest 'min_keep_count' regardless
# of age. Age is determined by the name of the snapshot, expected to
# be in ISO-8601 format and UTC, as used by the rest of this
# script. This is useful for deleting old snapshot archives to free up
# space.
##
# NOTE: time must be given as a datetime object, and utc is assumed.
def delete_older_than(loc, time, keep, sv):
    location = join(loc, sanitize(sv))
    stamp = time.isoformat(timespec='seconds')  # TODO: convert to utc?
    targets = map(lambda x: join(location, x), sorted(listdir(location)))
    i = 0
    while i + keep < len(targets):
        target = targets[i]
        # "<" works because ISO-8601 makes chronological and
        # lexicographical sorting identical.
        if target < join(location, stamp):
            cmd("delete old subvolume '%s'" % target,
                'btrfs', 'subvolume', 'delete', target)
        else:
            break
        i += 1


# === high-level snapshot actions ===

# # Usage: make_snaps(fro, to, *subvolumes)
# Make a read-only btrfs snapshot at 'to' for each given subvolume in
# 'from'. This is directly useful for being able to revert file
# changes (which is _NOT_ a backup!), and the snapshots are useful for
# (incrementally) copying subvolumes to other devices for real
# backups.
def make_snaps(fro, to, *svs):
    if not exists(fro, to):
        return False
    for sv in svs:
        snapshot(fro, to, sv)


# # Usage: copy_latest(fro, to, *subvolumes)
# Copy the latest snapshot for each given subvolume in 'from' to
# 'to'. This is useful for real backups, (incrementally) copying
# entire subvolumes between devices.
def copy_latest(fro, to, svs):
    if not exists(fro, to):
        return False
    for sv in svs:
        clone_or_update(fro, to, sv)


# # Usage: delete_old(snap_dir, time, *subvolumes, keep=1)
# Delete snapshots older than 'time' from 'snap_dir', keeping at least
# the latest 'min_keep_count' snapshots regardless of age. 'time' is a
# date/time string as used by "date --date=STRING". For example, a
# time of "3 days ago" will delete snapshots which are more than 3
# days old. This is useful when the device for 'from' doesn't have
# much space and the device for 'to' acts as an archive of the old
# states of 'from'.
def delete_old(snap_dir, time, *svs, keep=1):
    if not exists(snap_dir):
        return False
    for sv in svs:
        delete_older_than(snap_dir, time, keep, sv)
    # Sync everything to free up cleared space.
    cmd("sync '$1' to free deleted snapshots' space",
        'btrfs', 'filesystem', 'sync', snap_dir)
    # TODO: remove message when/if obsolete
    msg("Note that btrfs' cleanup of freed space may take a while longer.")


# === initial checks and setup ===

# # Usage: init()
# Runs initialization for the script. This should be called by main()
# and only main(), once and only once.
def init():
    global LOCKDIR, TIMESTAMP
    # Notify of debug mode if active
    if DEBUG:
        msg("Debug mode active. External commands will not really be ran.")
    # Also notify of VERBOSITY level if it's high enough
    dbg("VERBOSITY=%s" % VERBOSITY)

    # Check that required programs are installed.
    deps = ("btrfs cat chmod cp date find get-config get-data mkdir" +
            "mktemp readlink rm rmdir sleep sudo sync systemctl").split(' ')
    # TODO: sh->py
    cmd_eval("make sure commands exist:\n\t%s" % deps,
             'type', '-P', *deps)  # TODO: supress output

    # Check lock directory to prevent parallel runs.
    LOCKDIR = "/tmp/.backup-btrfs.lock"
    cmd("acquire lock", 'mkdir', LOCKDIR)
    # This is the only copy of the script running. Make sure we'll
    # clean up at the end.
    # TODO: sh->py
    add_exit_trap("cmd 'remove lock directory' rmdir '$LOCKDIR'")

    # This loop repeatedly runs "sudo -v" to keep sudo from timing
    # out, enabling the script to continue as long as necessary,
    # without pausing for credentials.
    ##
    # Note: It's not necessary to explicitly activate sudo mode first,
    # since the lock acquisition already uses sudo.
    ##
    # TODO: sh->py
    # msg "Starting sudo-refreshing loop."
    # ( while true; do
    #      cmd "wait just under a minute" sleep 50
    #      cmd-eval "refresh sudo timeout" "sudo -v"
    #  done; ) >/dev/null &
    # add-exit-trap "kill $! # sudo-refreshing loop"

    # Get timestamp for new snapshots.
    TIMESTAMP = datetime.utcnow().timeformat(timespec='seconds')


# Do not change the autogen stop line without also changing install()
# to match.
# ===== AUTOGEN STOP LINE =====

# === main stuff ===

# # Usage: get_config_path()
# Gets the path to the script's config.
def get_config_path():
    # TODO: sh->py translation pass 2 stopping point.

    # TODO: How to use the 'sh' package to run commands whose names
    # aren't valid Python identifiers? Or is there a better way to run
    # this?
    return sh['get-config']('backup-btrfs2/control_script.py', '-path')


# This explains how the config file works.
CONFIG_USE = """
Python script to run backup-btrfs2 functions. It works by calling
the make-snaps', 'copy-latest', and 'delete-old' functions with the
desired arguments. These functions work as follows:

make_snaps(fro, to, *subvolumes)

    Snapshot each listed subvolume under 'fro', saving the snapshots
    under 'to'. Note that 'fro' and 'to' must be under the same btrfs
    mount point, since snapshots merely copy references to the
    underlying data.

copy_latest(fro, to, *subvolumes)

    Copy the latest snapshot of each listed subvolume from 'fro' to
    'to'. Note that this is only useful if 'fro' and 'to' are on
    different partitions (and usually on different physical devices,
    like for backups), since otherwise lightweight snapshots could be
    used for the same effect without doubling disk usage.

delete_old(location, time, *subvolumes)

    Delete all snapshots older than 'time' from listed subvolumes
    under 'location'. Note that 'time' is recommended to be relative
    like 'three weeks ago' and should be longer than the frequency
    that backups are done to the location.

To see an example for clarity, it is recommended to choose to edit the
default config. It is a reasonable starting template for basic backup
cases."""


# # Usage: check_config()
# Checks that the config exists, exiting the script with a fatal error
# if not.
def check_config():
    # Check the config, explaining how it works if it isn't already set.
    # TODO: sh->py
    if not sh['get-config']('backup-btrfs2/control_script.py', '-verbatim',
                            '-what-do', CONFIG_USE):
        fatal("Could not get config.")


# # Usage: backup()
# Gets the backup config and runs it to do backups.
def backup():
    msg("Running backups.")
    check_config()  # Don't try running an imaginary config.
    # Source the config script to run it.
    # TODO: sh->py
    # source(get_config_path)
    # . "$(get-config-path)"


INSTALL_PATH = "/sbin/backup-btrfs.installed"
SYSTEMD_TARGET = "/etc/systemd/system"
AUTOGEN_MSG = """## DO NOT EDIT THIS AUTOGENERATED FILE!
# This file was made via 'backup-btrfs install'. If you want to change
# it, then make the appropriate change in your own config (and/or
# the script itself) and run 'backup-btrfs reinstall'.\n\n\n"""


# # Usage: install
# Makes sure there's a valid config, copies this to $install_path, and
# sets a systemd service/timer pair to automatically run this every
# hour or so.
def install():
    msg("Installing script as system command.")

    # Make sure the config exists.
    check_config()

    # Read in every line of this script, stopping at the autogen stop
    # line that precedes the "# === main stuff ===" section.
    ##
    # NOTE: Python counts trailing '\n' as part of the line. Thus it's
    # included in stop_at for matching, but excluded in 'script +='
    # lines.
    stop_at = "# ===== AUTOGEN STOP LINE =====\n"
    # TODO: Is there a less fragile way for script to read itself?
    script = ''
    with open(argv[0], 'r') as code:
        for line in code:
            if line == stop_at:
                break
            elif script == '':  # leading shebang line
                script += line + AUTOGEN_MSG
            else:
                script += line

    # Append function-wrapped config.
    script += """
# === config from install time, wrapped in function ===
def backup():
    msg('Running backups.')
    """ + config + "\n\n\n"

    # Append init-running and backup-running.
    config += '''
init()  # Run init manually; this has no main.
backup()  # Run backup manually; this has no main.
'''

    # Save to $install_path
    tmp_path = sh.mktemp()
    # TODO: sh->py
    cmd_eval("save derived script to temp file",
             'echo "$script" > "$tmp_path"')
    cmd("copy derived script from '%s'" % tmp_path,
        'cp', tmp_path, INSTALL_PATH)
    cmd("adjust permissions on '%s'" % INSTALL_PATH,
        'chmod', '0755', INSTALL_PATH)  # rwxr-xr-x
    cmd("remove temp file '%s'" % tmp_path, 'rm', tmp_path)

    # Copy systemd units.
    fro = cmd('get-data', 'backup-btrfs', '-path', sudo=False)
    cmd("copy systemd service",
        'cp', join(fro, 'backup-btrfs.service'), SYSTEMD_TARGET)
    cmd("copy systemd timer",
        'cp', join(fro, 'backup-btrfs.timer'), SYSTEMD_TARGET)

    # Enable and start systemd service+timer pair.
    ##
    # NOTE: Don't enable backup-btrfs.service directly; the timer does it.
    cmd("enable systemd timer",
        'systemctl', '--quiet', 'enable', 'backup-btrfs.timer')
    cmd("start systemd timer", 'systemctl', 'start', 'backup-btrfs.timer')

    # Tell user it's been installed.
    msg("Install complete! Here are the systemd timers to confirm.")
    cmd("list systemd timers", 'systemctl', 'list-timers', sudo=False)


# # Usage: reinstall()
# Uninstall and reinstall the script from the system.
def reinstall():
    msg("Reinstalling with latest config and script version.")
    uninstall()
    install()


# # Usage: uninstall()
# Remove from install_path and undo systemd changes.
def uninstall():
    msg("Uninstalling script.")

    # Stop and disable systemd service+timer pair.
    cmd("stop systemd timer", 'systemctl', 'stop', 'backup-btrfs.timer')
    cmd("disable systemd timer",
        'systemctl', '--quiet', 'disable', 'backup-btrfs.timer')
    cmd("disable systemd service",
        'systemctl', 'disable', 'backup-btrfs.service')

    # Remove systemd units.
    cmd("remove systemd timer",
        'rm', join(SYSTEMD_TARGET, 'backup-btrfs.timer'))
    cmd("remove systemd service",
        'rm', join(SYSTEMD_TARGET, 'backup-btrfs.service'))

    # Remove from install_path.
    cmd("remove installed derived script",
        'rm', INSTALL_PATH)

    # Tell user it's been removed.
    msg("Uninstall complete.")


USAGE = """Usage: backup-btrfs [options ...] {action} [options ...]

Run btrfs backups.


Actions:

backup     Run btrfs backups according to config.
install    Bundle script and config into no-arg system script and set
           systemd to automatically run it every hour or so.
reinstall  Redo install with latest script and config versions.
uninstall  Remove installed file and systemd units.
usage      Show this usage information.


Options:

DEBUG      Simulate actions and increase verbosity to maximum. This is
           good for testing purposes, such as after changing the
           control script.
quiet      Decrease verbosity by one level.
verbose    Increase verbosity by one level.


Note: Verbosity currently ranges from -2 to +3 and defaults to 0.
Note: Arguments may be abbreviated if unambiguous.
"""


# # Usage: usage()
# Show usage message.
def usage():
    msg(USAGE)


# # Usage: main()
# Run the script.
def main():
    global VERBOSITY, DEBUG
    acts = ['backup', 'install', 'reinstall', 'uninstall', 'usage']
    opts = ['DEBUG', 'quiet', 'verbose']
    VERBOSITY = 0
    action = ''
    for arg in argv[1:]:
        if arg in acts:
            if action == '':
                action = arg
            else:
                fatal("Multiple actions given: %s, %s, [...]." % (action, arg))
        elif arg in opts:
            if arg == 'DEBUG':
                DEBUG = True
                VERBOSITY = 3
            elif arg == 'verbose':
                VERBOSITY += 1
            elif arg == 'quiet':
                VERBOSITY -= 1
            else:
                fatal("WTF? (opt %s)" % arg)
        else:
            fatal("Unknown argument '%s'." % arg)
        args = args[1:]

    if action in acts:
        if action == "usage":
            usage()
        else:
            init()
            eval('%s()' % action, locals(), globals())
    elif action == '':
        usage()
        fatal("No action.")
    else:
        fatal("WTF? action=%s." % action)


main()
