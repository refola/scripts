#!/usr/bin/env bash
# Cache a bunch of regularly-used folders for faster future access

cfg="cache-places/folders"
# The IFS and extra parentheses turn $folders into an array.
IFS=$'\n'
folders=( $(get-config "$cfg" \
    -what-do "list of folders to cache" \
    -var-rep ) ) || exit 1

quiet=''
delay="15s"
concurrency=1
cfg_path="$(get-config "$cfg" -path)"
w() { echo "\e[1m$*\e[0m"; } # white text to stand out
usage="$(w $(basename "$0")) [$(w -q)] [{delay}] [$(w -fork) [{count}]]

Caches everything listed in ${cfg_path/#$HOME/'~'}.

$(w Arguments:)

  $(w arg)    param  usage

  $(w -q)            Suppress this usage info without using other args.

  $(w )       delay  How long to delay caching by (e.g., '5' or '5s' for 5
                seconds, '5m' for 5 minutes, '5h' for 5 hours, and
                '5d' for 5 days). Default is $delay.

  $(w -fork)  count  How many caching forks to run. This can change
                performance. Without '-fork', the default is no
                concurrency ('1'). With '-fork', the default is
                'infinity'. See the Concurrency Note below.

$(w Concurrency Note:) Forking is probably only useful if you have
replicating RAID or a solid state drive, since randomizes otherwise
sequential reads and random accesses tend to be slower on
spinning-rust drives. In the author's limited tests, forking works
best with as many forks as there are disks, or the default of
'infinity' with solid state drives. The user is encouraged to test
various values with their particular disk and filesystem setup, making
sure to run '$(w 'echo 3 | sudo tee /proc/sys/vm/drop_caches')'
between tests to ensure valid results.
"

# Parse arguments
if [ -z "$1" ]; then
    echo -e "$usage" # Accept no-arg default, but notify user.
else
    while [ -n "$1" ]; do
        if [ "$1" = "-q" ]; then
            quiet=true
        elif [ "$1" = "$(echo "$1" | egrep "^[0-9]+[smhd]?$")" ]; then
            delay="$1"
        elif [ "$1" = "-fork" ]; then
            concurrency="infinity"
            if [ -n "$2" ] && [ "$2" = "$(echo "$2" | egrep "^[0-9]+$")" ]; then
                concurrency="$2"
                shift # eat extra arg
            fi
        else
            w "Unknown argument '$1'. Aborting."
            echo "$usage"
            exit 1
        fi
        shift
    done
fi

# Make implicit unit of seconds explicit.
if [ "${delay/%[smhd]/}" = "$delay" ]; then
    delay="${delay}s"
fi

# Notify of delay iff delay happens.
if [ "${delay/%[smhd]/}" != "0" ]; then
    echo -e "$(w "Waiting $delay before caching stuff....")"
    sleep "$delay"
fi

# Caches a single folder, wrapping the "cache-folder" command for prettiness.
cache-one() {
    local folder="$1"
    if [ -d "$folder" ] && [ ! -h "$folder" ]; then # check that it's a folder and not a symlink
        size="$(du -sh "$folder" 2>/dev/null)"
        size="${size%$'\t'$folder}"
        export TIMEFORMAT="%Es" # Make Bash's time command show only ellapsed time.
        duration="$( (time cache-folder "$folder" > /dev/null) 2>&1 | grep -v 'Permission denied')"
        echo "Took $duration to cache $size in $folder."
    else
        if [ -h "$folder" ]; then
            echo -e "$(w "Skipping symlink: $folder")"
        else # the "! -d" case
            echo -e "$(w "Folder doesn't exist: $folder")"
        fi
    fi
       sleep 0.01 # BUG: This is to help prevent "winning" the race
                  # condition in cache-em-all()'s logic.
}

# Caches every folder in the list.
cache-em-all() {
    echo -e "$(w "Caching configured list of commonly-used folders. This may take a while....")"
    ## Forking logic:
    # 1. Always fork.
    # 2. If infinite concurrency, go to next fork.
    # 3. If at concurrency limit, wait for a fork to finish.
    # 4. Otherwise, decrease concurrency for next iteration.
    ## BUG
    # If a fork finishes at any time besides "wait -n", then we will
    # inadvertantly be one fork less concurrent than requested.
    for folder in "${folders[@]}"; do
        cache-one "$folder" &
        if [ "$concurrency" = "infinity" ]; then
            continue
        elif [ "$concurrency" -le "1" ]; then
            wait -n
        else
            ((concurrency--))
        fi
    done
    wait # ... for remaining forks to finish
    echo -e "$(w "Done! ^.^")"
}

cache-em-all # Gotta...
