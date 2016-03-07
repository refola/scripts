#!/bin/bash
## get-data.sh
# Read in data for a script from the data directory of this scripts repository.

data_prefix="$(dirname "$(cmdir "$0")")/data" || exit 1
usage="Usage: $(basename "$0") data_name [-path]

Outputs the contents of the given data file, or just the path if
'-path' is passed.

Data is found at $data_prefix.
"

main() {
    if [ "$#" = 0 ]; then
        echo "$usage"
        exit 1
    else 
        data_path="$data_prefix/$1"
        if [ "$2" = "-path" ]; then
            echo "$data_path"
        else
            cat "$data_path"
        fi
    fi
}

main "$@"
