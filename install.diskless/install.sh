#!/bin/sh
# Install Alpine Linux in a diskless setup.

if [ "$(id -u)" != "0" ]; then
    echo "ERROR: this script must be run as root or with sudo."
    exit 1
fi

if [ "$(uname -v | grep -c Alpine)" != "1" ]; then
    echo "ERROR: This command must be run on Alpine Linux." >&2
    exit 1
fi

printf "This script will set up Alpine Linux in a diskless setup. Some notes:\n\n"
printf "- \"answer-file.txt\" should be configured to the settings you require.\n\n"
printf "- The drive should contain at least two partions: one for booting from the drive and one for holding the overlays.\n\n"
printf "- The overlay partition can be sized as desired.\n\n"
printf "- The overlay partition will be ERASED during this setup.\n\n"
printf "- The overlays are mounted in read-only mode by default. Edit /etc/fstab after running this script to permanently mount these in read-write mode or use make-rw.sh and make-rw.sh to do so temporarily.\n\n"
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

# Add the ext* utilities and format the overlay partition.
apk add e2fsprogs
mkfs.ext4 -F "${OVERLAY_DEVICE}"

# Set up the overlay.
mkdir -p "${OVERLAY_MOUNT_POINT}"
mount "${OVERLAY_DEVICE}" "${OVERLAY_MOUNT_POINT}"
mkdir "${OVERLAY_MOUNT_POINT}/home"
mkdir "${OVERLAY_MOUNT_POINT}/usr"
mkdir "${OVERLAY_MOUNT_POINT}/._home_work"
mkdir "${OVERLAY_MOUNT_POINT}/._usr_work"

# Set the boot drive to be mounted in read-only mode.
sed -i 's/vfat\ rw,/vfat\ ro,/' /etc/fstab

# Update the file-system table to properly mount everything on boot.
cat <<EOF >> /etc/fstab
# Mount the overlays in read-only mode. The overlay device must be mounted in
# read-write mode if either of the overlays are.
${OVERLAY_DEVICE} ${OVERLAY_MOUNT_POINT} ext4 ro,defaults 0 0
overlay /home overlay lowerdir=/home:${OVERLAY_MOUNT_POINT}/home 0 0
overlay /usr overlay lowerdir=/usr:${OVERLAY_MOUNT_POINT}/usr 0 0

# Mount the overlays in read-write mode. The overlay device must be mounted in
# read-write mode if either of the overlays are.
# ${OVERLAY_DEVICE} ${OVERLAY_MOUNT_POINT} ext4 defaults 0 0
# overlay /home overlay lowerdir=/home,upperdir=${OVERLAY_MOUNT_POINT}/home,workdir=${OVERLAY_MOUNT_POINT}/._home_work 0 0
# overlay /usr overlay lowerdir=/usr,upperdir=${OVERLAY_MOUNT_POINT}/usr,workdir=${OVERLAY_MOUNT_POINT}/._usr_work 0 0
EOF

# Commit all of the changes made during installation.
lbu commit -d

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
