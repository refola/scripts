#!/bin/bash
# script to run other backup programs/scripts for different types of backup stuff or something

echo "This script may need justification...."

#cleanhome all # counterproductive to btrfs snapshots, unless there's a guarantee that it *always* happens
#snapinternal # functionality merged into more sophisticated btrfsbackup script
#snapexternal # functionality merged into more sophisticated btrfsbackup script
backup.2014-03-15.0843 # happens before btrfsbackup since it's only used for the phone now
btrfsbackup # yay shiny new script!
