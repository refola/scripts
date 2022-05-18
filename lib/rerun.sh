#!/usr/bin/env bash
## rerun.sh
# Repeatedly run a command whenever its argument files change.

usage() {
    local cmd=rerun
    cat << EOF
$cmd [options...] command args [...]
$cmd [options...] {--file | -f} file... {--command | -c} command [args...]

Repeatedly run a command whenever the file(s) it acts on change, or
when any given file changes.

In the first case, the command's arguments are examined and valid
files are watched.

In the second case, all files must be immediately after the "-f"
argument and the command (with its args) after the "-c" argument, and
only explicitly given files are watched.

Options:

--force    Don't exit on nonzero command return value (i.e., only
           exit when interrupted with, e.g., ^C).
--debug    Show diagnostic information.

EOF
}

## wait file[...]
# Waits for the file(s) at given path(s) to be updated if a supported
# utility is installed, otherwise falling back to a constant wait time
wait() {
    local ns=({1..15})
    local traps="$(trap)"
    trap -- 'return 1' "${ns[@]}"

    if which fswatch &>/dev/null; then
        # Nice cross-platform tool: https://github.com/emcrisostomo/fswatch
        fswatch -1 "$@" &>/dev/null
    elif which inotifywait &>/dev/null; then
        # Linux-specific, requires inotify-tools
        echo "rerun: 'fswatch' not found."
        echo "       Falling back to Linux-specific inotifywait."
        inotifywait "$@" &>/dev/null
    else
        # TODO: repeatedly check modify time as a better fallback

        # Ideal fallback logic:
        # while not changed since last saved time (global var ☹):
        #  sleep 0.05 (or whatever small increment is decently light & fast)

        # (`find "$1" -mtime -5s` doesn't work on GNU `find` because
        # it's somehow stuck with rounded-up 24-hour time periods as
        # of version 4.8.0 in 2021)

        # Is `stat` similar enough between Linux and MacOS?

        # Modification time as seconds since epoch:
        # GNU/Linux: stat -c %Y "$1"

        # Current seconds since epoch:
        # GNU/Linux: date +%s

        # Fallback which at least gives a moment's pause instead of
        # completely thrashing the CPU
        echo "rerun: No supported file-watching tool found."
        echo "       Falling back to 'sleep 1'."
        sleep 1
    fi

    trap - "${ns[@]}"
    eval "$traps"
}

main() {
    local cmd=()
    local files=()
    local force='' debug='' status=''

    # process args
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --debug)
                debug=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            -f|--file)
                # explicit file list first
                shift
                while [ "$#" -gt 1 ]; do
                    # add files to list until command flag found
                    case "$1" in
                        -c|--command)
                            shift
                            cmd=("$@")
                            set --
                            break
                            ;;
                        *)
                            files+=("$1")
                            shift
                            ;;
                    esac
                done
                ;;
            *)
                # implicit "figure out which args are files"
                cmd=("$@")
                shift
                while [ "$#" -gt 0 ]; do
                    if [ -e "$1" ]; then
                        files+=("$1")
                    fi
                    shift
                done
                ;;
        esac
    done

    # insufficient args -> show usage
    if [ "${#files}" -eq 0 ] || [ "${#cmd}" -eq 0 ]; then
        usage
        return 1
    fi

    # debug...
    [ -n "$debug" ] && echo "cmd=(${cmd[*]}), files=(${files[*]})"

    # keep running the command
    while true; do
        "${cmd[@]}"
        status="$?"
        [ -n "$force" ] || [ "$status" -eq 0 ] ||
            return "$status"
        wait "${files[@]}" ||
            return "$status"
    done
}

main "$@"
