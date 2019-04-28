#!/usr/bin/env bash
# pidlock.sh
# Manage lock directories associated with given processes.

USAGE="pidlock command [args ...]

Manage global locks with associated PIDs (process IDs).

A typical program flow would use 'locked' and 'lock' on program start
to check for and create the lock, 'addpids' on each fork to add child
processes, 'remove-pids' when a child process is known to have exited,
and 'kill' on exit to kill all child processes.

Commands are as follows:

pidlock addpids lock-name [PIDs...]
        Add given PID(s) to given lock. Returns 1 on nonexistent lock,
        2 on existing PID, or 3 on filesystem access error.

pidlock help
        Show this message and exit.

pidlock kill lock-name
        Kills all processes matching PIDs under the given lock and
        removes the lock. Returns 0 on success, 1 on nonexistent lock,
        2 if there's an error killing the processes, or 3 if there's a
        filesystem access error.

pidlock lock lock-name [PIDs...]
        Attempt to create a lock of the given name and save an
        associated list of PIDs under it. Returns 0 on success, 1 on
        failure creating lock, and 2 on failure recording PIDs.

*pidlock locked lock-name
        Return 0 if the given lock exists, or 1 if it doesn't exist.

pidlock path lock-name
        Echoes the given lock's path, for manual
        inspection/manipulation.

*pidlock remove-pids lock-name [PIDs...]
*pidlock remove-pids lock-name all
        Remove given PIDs from given lock. Remove all PIDs if 'all' is
        passed. Returns 0 on success, 1 on nonexistent lock, and 2 on
        filesystem access error.

*pidlock unlock lock-name
        Remove given lock if it exists and is empty. Returns 0 on
        success, 1 on nonexistent lock, and 2 on 'rmdir' failure.

NOTE: Commands with '*' before them haven't been tested in actual
script usage.
"

DIR='' # set in main()

addpids() {
    local pid
    [[ -d "$DIR" ]] || return 1
    cd "$DIR" || return 3
    for pid in "$@"; do
        [[ ! -e "$pid" ]] || return 2
        touch "$pid" || return 3
    done
}

help() { echo "$USAGE"; }

kill() {
    local pid
    [[ -d "$DIR" ]] || return 1
    cd "$DIR" || return 3
    for pid in *; do
        command kill "$pid" || return 2
        rm "./$pid" || return 3
    done
    rmdir "$DIR" || return 3
}

lock() {
    local pid
    mkdir "$DIR" || return 1
    shift
    for pid in "$@"; do
        touch "$DIR/$pid" || return 2
    done
    return 0
}

locked() { [[ -d "$DIR" ]] || return 1; }

path() { echo "$DIR"; }

remove-pids() {
    local pid
    [[ -d "$DIR" ]] || return 1
    cd "$DIR" || return 3
    if [[ "$1" = "all" ]]; then
        rm ./* || return 2
        return 0
    fi
    for pid in "$@"; do
        rm ./"$pid" || return 2
    done
}

unlock() {
    [[ -d "$DIR" ]] || return 1
    rmdir "$DIR" || return 2
}

main() {
    local cmd="$1" name="$2" d
    shift 2
    local pids=("$@")
    d="$(get-config "pidlock" -path)"
    mkdir -p "$d"
    DIR="$d/$name"
    case "$cmd" in
        help)
            help
            exit 0
            ;;
        kill|locked|path|unlock)
            if [[ "${#pids[@]}" != '0' ]]; then
                echo "Error: PIDs given for non-PID-using subcommand '$cmd'."
                return 255
            fi
            $cmd
            ;;
        addpids|lock)
            $cmd "${pids[@]}"
            ;;
        *)
            help
            exit 1
            ;;
    esac
}

main "$@"
