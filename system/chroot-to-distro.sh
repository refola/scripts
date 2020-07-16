#!/usr/bin/env bash

declare USAGE ch
declare -a mounts umounts umount_fails

USAGE="Usage: $(basename "$0") mount-point [options ...]
Sets things up, chroots into mount-point, and cleans up when done.

Options:

--bind
    Bind mount mount-point to itself. (Fixes odd errors with, e.g.,
    Arch-based distros if mount-point isn't already its own mount.)

--home
    Also bind /home.

--net
    Copy host's /etc/resolv.conf to chroot. (Try if DNS fails.)
"

usage() {
    echo "$USAGE"
}

fail() {
    echo "$@" >&2
    exit 1
}

# order mounts and unmounts
mounts=() # everything directly bind-mountable
umounts=() # mounts, with recursion reversed and tmp added
for mnt in dev dev/pts proc run sys; do
    mounts+=("$mnt")
    umounts=("$mnt" "${umounts[@]}")
done
umounts=(tmp "${umounts[@]}")

# handle args
if [ -z "$1" ]; then
    usage
    exit 1
fi
ch="$1"; shift
mount_ch() { false; } # this needs to return true or false later; default false
for arg in "$@"; do
    case "$arg" in
        --bind)
            # add $ch to mounts
            # TODO: more easily verifiable logic
            mount_ch() { true; }
            # . is the chroot target itself since paths are relative
            umounts=("${umounts[@]}" .)
            ;;
        --net)
            if [[ -f "$ch/etc/resolv.conf" ]] || [[ ! -e "$ch/etc/resolv.conf" ]]; then
                sudo cp "/etc/resolv.conf" "$ch/etc/resolv.conf"
            else
                echo "Error: chroot's /etc/resolv.conf is not a regular file."
                echo "Please exit chroot and manually handle it if networking fails."
            fi
            ;;
        *)
            fail "Bad arg: $arg"
            ;;
    esac
done

echo "Setting up chroot for $ch."

# first mount: $ch iff in needs bind mounting
if mount_ch; then
    sudo mount --bind "$ch" "$ch"
fi
# regular mounts
for x in "${mounts[@]}"; do
    echo "Binding $x to $ch/$x."
    sudo mount -o bind "/$x" "$ch/$x"
done
# last mount: $ch/tmp (no binding)
sudo mount -t tmpfs tmpfs "$ch/tmp"

# actual chroot
echo "Chrooting into $ch."
sudo chroot "$ch"

# cleanup
echo "Undoing special mounts in $ch."
for m in "${umounts[@]}"; do
    if ! sudo umount "$ch/$m"; then
        umount_fails+=("$ch/$m")
    fi
done

# show any failed unmounts
if [ ${#umount_fails[@]} != 0 ]; then
    echo "Could not unmount the(se) location(s):"
    printf "\t%s\n" "${umount_fails[@]}"
    echo "Please examine them manually and consider filing a bug report"
    echo "if you didn't do something to interfere with them."
fi
