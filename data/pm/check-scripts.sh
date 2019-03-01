#!/usr/bin/env bash
cd "$(dirname "$(readlink -f "$0")")" || exit 1
shellcheck --shell=bash ./{info,install,remove,search,upgrade}/*
