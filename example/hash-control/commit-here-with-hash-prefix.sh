#!/usr/bin/env bash
# Make a git commit with given message, hash prefix, and other
# arguments (default: commit all).
here="$(dirname "$(readlink -f "$0")")"
cd "$here" || exit 1
message="$1"
prefix="$2"
shift 2
args=("$@")
if ! echo "${args[@]}" | grep -q nonce; then
    args+=(./nonce)
fi
if [ -z "$1" ]; then
    args=(--all)
fi
echo "Args: ${args[*]}"

nonce=0
hash=
git add ./nonce
git commit -m "Dummy commit before reset...."
# TODO: This is really slow. Is there a way to do this without running
# 4+ processes and doing 4+ disk writes each iteration?
while [ "${hash:0:${#prefix}}" != "$prefix" ]; do
    git reset HEAD~ &>/dev/null
    git add "${args[@]}" # Because resetting un-adds
    ((nonce++))
    echo "$nonce" > ./nonce
    git commit -m "$message" "${args[@]}" &>/dev/null
    hash="$(git rev-parse HEAD)"
done

echo "Commit made."
echo "Hash: $hash"
echo "Luck nonce: $nonce"
