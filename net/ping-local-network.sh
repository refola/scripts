#!/usr/bin/env bash

ERR_NO_NET_TOOL="Error: No known-to-script-author tool found to get network
info. Can't ping unknown network."

ERR_NO_PREFIX="Error: Could not find address in 192.168.x.y namespace. Please check
'ip addr' or 'ifconfig' if you think you should be connected to such a
namespace. Otherwise please open a bug report with information on
if/why/how you think it would be appropriate to support your network's
namespace and/or tools."

data=
if which ip >/dev/null; then
    data="$(ip addr)"
elif which ifconfig >/dev/null; then
    data="$(ifconfig)"
else
    echo "$ERR_NO_NET_TOOL"
    exit 1
fi

prefix=
for i in {0..255}; do
    pre="192.168.$i."
    if echo "$data" | grep -q "$pre"; then
        prefix="$pre"
        break
    fi
done

if [ -z "$prefix" ]; then
    echo "$ERR_NO_PREFIX"
    exit 1
fi

doit() {
    # Ping $1 with count=1, wait=5s, and only show results if successful.
    ping -c 1 -W 5s "$1" | grep -B 1 "1 received" | grep -o "$1"
}

for ((x=1; x<255; x++));
do
    doit "$prefix$x" &
done | sort --version-sort # This sort adds an implicit "wait".
