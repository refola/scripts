#!/usr/bin/env bash
run() {
    echo "Running '$1' to $2."
    eval "$1"
}
run "sync" "flush buffers"
run "echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null" "drop caches"
