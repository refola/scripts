#!/usr/bin/env bash
## todo.sh
# Simple todo list manager.

usage="todo {add {task} | done | get | help | shuffle | sort}

Manage an unsorted to-do list.

Actions are as follows:

add task with as much detail as needed
    Add a new item to the list.

done
    Show and remove the top item from the list.

get
    Show the top item from the list.

help
    Show this usage info and exit.

shuffle
    Reorder the items in the list and show the new top one.

sort
    Sort items lexicographically and show the new top one.
"

list="$(get-config todo/list -path)"
ltmp="$list.tmp"
mkdir -p "$(dirname "$list")"
touch "$list"

add() { echo "$*" >> "$list"; }
_done() {
    get
    tail -n+2 "$list" > "$ltmp"
    mv "$ltmp" "$list"
}
get() { head -n1 "$list"; }
help() { echo "$usage"; }
shuffle() {
    shuf "$list" > "$ltmp"
    mv "$ltmp" "$list"
    get
}
_sort() {
    LC_ALL=C sort "$list" > "$ltmp"
    mv "$ltmp" "$list"
    get
}

main() {
    case "$1" in
        'done'|sort)
            "_$1" "${@:2}" ;;
        add|get|help|shuffle)
            "$@" ;;
        *)
            help
            exit 1 ;;
    esac
}

main "$@"

