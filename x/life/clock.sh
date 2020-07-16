#!/usr/bin/env bash
cfg="$(get-config clock -path)"
mkdir -p "$cfg"
echo "$(date -uIs) ${1-${0/*\/clock-/}}" >> "$cfg/log"
