#!/bin/sh
# Make the overlays read-only again. This should only be called after make-rw.sh
# has been called.

if [ "$(id -u)" != "0" ]; then
    echo "ERROR: this script must be run as root or with sudo."
    exit 1
fi

if [ "$(uname -v | grep -c Alpine)" != "1" ]; then
    echo "ERROR: This command must be run on Alpine Linux." >&2
    exit 1
fi

# Get the variables used to mount the overlays.
. "$(dirname "$(readlink -f "$0")")/answer-file.txt"

umount /home
umount /usr
mount -o remount,ro "${OVERLAY_MOUNT_POINT}"
mount -o remount,ro "${BOOT_MOUNT_POINT}"
