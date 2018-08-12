#!/bin/sh
# Make the overlays writable. make-ro.sh should be called once all changes have
# been done.

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

mount -o remount,rw "${BOOT_MOUNT_POINT}"
mount -o remount,rw "${OVERLAY_MOUNT_POINT}"
mount -t overlay overlay -o "lowerdir=/home,upperdir=${OVERLAY_MOUNT_POINT}/home,workdir=${OVERLAY_MOUNT_POINT}/._home_work" /home
mount -t overlay overlay -o "lowerdir=/usr,upperdir=${OVERLAY_MOUNT_POINT}/usr,workdir=${OVERLAY_MOUNT_POINT}/._usr_work" /usr
