#!/usr/bin/env bash
declare -A chars
msg="$1"
len="${#msg}"
i=0

inc(){
    local x="${chars[$1]}"
    ((x++))
    chars[$1]="$x"
}

while [ "$i" -lt "$len" ]; do
    char="${msg:$i:1}"
    inc "$char"
    ((i++))
done

for i in "${!chars[@]}"; do
    echo "${chars[$i]} $i"
done |
    sort -n |
    sed -r 's/^([0-9]+) (.)$/\2: \1/g'
