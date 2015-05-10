#!/bin/bash

echo "This is called.sh. VAR1 is $VAR1."

export VAR1="set by called.sh"
export VAR2="also set by called.sh"
VAR3="another var also set by called.sh, but not exported"

echo "VAR1 changed and exported. VAR2 set and exported."
echo "VAR3 set and not exported. Exiting called.sh."
