#!/usr/bin/env bash

exit1() { echo "exit1" ; }
exit2() { echo "exit2" ; }

trap exit1 EXIT
trap exit2 EXIT # overrides previous trap

trap "echo trap1" SIGINT SIGTERM
trap "echo trap2" SIGINT SIGTERM # overrides previous trap

echo "sleeping 10s"
sleep 10 # is killed before trap is activated

## Output without ^C:
# sleeping 10s
# exit2

## Output with ^C:
# sleeping 10s
# trap2
# exit2

## Conclusion:
# Traps do not stack, so any trap should be defined in at most one
# place. It may be worthwhile to build a "trap stack" function that,
# for a given trap, maintains a list of functions for the given trap,
# and after being called resets the trap to the full list.
