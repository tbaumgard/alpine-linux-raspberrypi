#!/bin/sh
# Install Alpine Linux in a sys setup.

if [ "$(id -u)" != "0" ]; then
    echo "ERROR: this script must be run as root or with sudo."
    exit 1
fi

if [ "$(uname -v | grep -c Alpine)" != "1" ]; then
    echo "ERROR: This command must be run on Alpine Linux." >&2
    exit 1
fi

printf "This script will set up Alpine Linux in a sys setup. Some notes:\n\n"
printf "- \"answer-file.txt\" should be configured to the settings you require.\n\n"
printf "- The drive should contain at least two partions: one for booting from the drive and one for holding the root partition.\n\n"
printf "- The root partition can be sized as desired.\n\n"
printf "- The root partition will be ERASED during this setup.\n\n"
printf "- The root password will be left empty. Use passwd to change it.\n\n"

if [ "${AUTOMATIC_MODE}" != "Y" ]; then
    printf "Continue? [y/N] "
    read CONTINUE
else
    CONTINUE="Y"
fi

case "${CONTINUE}" in
    [Yy]*) ;;
    *) exit;;
esac

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
ANSWER_FILE="${SCRIPT_DIR}/answer-file.txt"

# Include the answer file and export only the variables that should be passed to
# setup-alpine.
. "${ANSWER_FILE}"
export APKCACHEOPTS
export APKREPOSOPTS
export DISKOPTS
export DNSOPTS
export HOSTNAMEOPTS
export INTERFACESOPTS
export KEYMAPOPTS
export LBUOPTS
export PROXYOPTS
export SSHDOPTS
export TIMEZONEOPTS

# Mount the boot partition of the drive in r/w mode so that it can be modified.
mount -o remount,rw "${BOOT_MOUNT_POINT}"

# Set up networking first so that NTP can properly sync so that setup-alpine
# doesn't choke due to an incorrect date.
echo "${INTERFACESOPTS}" | setup-interfaces -i
/etc/init.d/networking start

# Set up NTP now so that setup-alpine doesn't choke due to an incorrect
# date. This requires networking to be set up above. Also flag setup-alpine to
# not set up NTP.
setup-ntp ${NTPOPTS}
export NTPOPTS="-c none"

# Finally, now that networking and NTP have been configured to avoid choking,
# begin setup-alpine.
setup-alpine -e

if [ "${USE_SOFTWARE_CLOCK}" == "Y" ]; then
   # Enable software clock and disable the hardware clock if requested.
   rc-update add swclock boot
   rc-update del hwclock boot
fi

# Add the ext* utilities and format the root partition.
apk add e2fsprogs
mkfs.ext4 -F "${ROOT_DEVICE}"

# Commit the changes now so that the *.apkovl.tar.gz file is created for the
# setup-disk step below.
lbu commit -d

# Mount the root partition and set up disk-based installation.
mount "${ROOT_DEVICE}" /mnt
setup-disk -o "$(echo ${BOOT_MOUNT_POINT}/*.apkovl.tar.gz)" /mnt

# Update the file-system table to properly mount everything on boot.
cat <<EOF >> /etc/fstab
# Mount the boot drive partition.
${BOOT_DEVICE} ${BOOT_MOUNT_POINT} vfat defaults 0 0

# Bind-mount /boot so that it gets updated properly without manual intervention.
${BOOT_MOUNT_POINT}/boot /boot none rw,defaults,bind 0 0
EOF

# Make sure the root is the correct drive to be booted from.
sed -i "$ s/$/ root=$(echo "${ROOT_DEVICE}" | sed 's|/|\\/|g')/" "${BOOT_MOUNT_POINT}/cmdline.txt"

printf "\n### Installation is complete.\n"

if [ "${AUTOMATIC_MODE}" != "Y" ]; then
    echo -n "Reboot now? [Y/n] "
    read REBOOT_CHECK
else
    REBOOT_CHECK="Y"
fi

case "${REBOOT_CHECK}" in
    [Nn]*) ;;
    *) reboot;;
esac
