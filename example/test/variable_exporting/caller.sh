#!/bin/bash

# Get script location
DELINKED=`readlink -f "$0"`
HERE="`dirname "$DELINKED"`"
cd $HERE

VAR1="set by caller"
echo "VAR1 is $VAR1."

# Have to dot the file to make the exports do anything....
. ./called.sh

echo "VAR1 is $VAR1."

./called_later.sh

