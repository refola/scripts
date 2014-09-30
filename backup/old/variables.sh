#!/bin/bash
# Variable-setting script for other backup scripts to deduplicate stuff
# This must be called in the backup scripts with ". $HERE/variables.sh", otherwise the variable-setting is excessively transient.

# Rules file location relative to script
RULES_LARGE="$HERE/rules-home-large"
RULES_MEDIUM="$HERE/rules-home-medium"
RULES_SMALL="$HERE/rules-home-small"
RULES_PHONE="$HERE/rules-phone"

# Various options for rsync to do things just so
OPTS_MAIN="--delete --delete-excluded --progress --recursive --times"
# Links are important, but need an EXT file system
OPTS_EXT="--links"
# Lots of options to disable stuff FAT doesn't support.
# See <http://www.monperrus.net/martin/backup+from+ext3+to+vfat+with+rsync>.
OPTS_FAT="--no-o --no-g --no-p --modify-window=1 --safe-links"

# Options for setting where to backup from and to
USER=`whoami`
export AWAY="/run/media/$USER" # Exported for use by usage.sh
# Where to copy files from -- not ~ in this case because I moved my official "home" folder to /home/mark/.home to unclutter my /home/mark directory
HOME="/home/$USER"
