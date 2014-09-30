#!/bin/bash
# Echos the syntax for the calling backup script
# Syntax: $HERE/usage.sh name_of_backup_script rsync_backup_action
# I hope the variables work from variables.sh which should've been called before.
echo "Usage: $1 suffix"
echo "This uses rsync to backup $2."
echo "A list of locations in \"$AWAY\" follows."
ls -A $AWAY
