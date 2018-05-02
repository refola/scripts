#!/usr/bin/env bash

cmds=( grub2-mkconfig grub-mkconfig )
dests=( /boot/grub2/grub.cfg /boot/grub/grub.cfg )

for _cmd in "${cmds[@]}"; do
    x="$(which "$_cmd" 2>/dev/null)"
    if [ -n "$x" ]; then
        cmd="$_cmd"
    fi
done
if [ -z "$cmd" ]; then
    echo "Could not find grub config generation command in [${cmds[@]}]."
    echo "Exiting."
    exit 1
fi

for _dest in "${dests[@]}"; do
    if [ -f "$_dest" ]; then
        dest="$_dest"
    fi
done
if [ -z "$dest" ]; then
    echo "Could not find grub config destination file in"
    echo "${dests[@]}. Exiting."
    exit 1
fi

echo "\"update-grub\" probably doesn't exist on this system. It's
running ${MACHTYPE}, not Ubuntu! This script is just a convenience to
run \"$cmd -o $dest\" for you. To keep it from being too convenient,
you still have to get root your own way for $(basename "$0")."

"$cmd" -o "$dest" "$@"
