# `install.sys`

The `install.sh` script is used to install [Alpine Linux](https://alpinelinux.org) on the [Raspberry Pi](https://www.raspberrypi.org) using a *sys* setup. This is meant for setups that need read-write use of the drive the majority of the time. This was tested on a [Raspberry Pi Model 3 B+](https://www.raspberrypi.org/products/raspberry-pi-3-model-b-plus/) but may work with other versions and other similar hardware.

## Instructions

Note: You can use the [Raspberry Pi](https://wiki.alpinelinux.org/wiki/Raspberry_Pi) article on the Alpine Linux wiki as a general guide and as a means to understand what's going on.

1. Partition the SD card or USB drive that will be used. At least two partitions are needed if the script is used unmodified, one `FAT32` partition for booting and another for the root partition. 128 MB for the boot partition should be fine. The root partition can be as large as needed, and 500 MB is a safe lower bound.

2. [Download the latest version of Alpine Linux](https://alpinelinux.org/downloads/) for Raspberry Pi, either `armhf` or `aarch64`. The Raspberry Pi 3 B+ has a 64-bit processor and can use the `aarch64` version.

3. Mount the boot partition and extract the downloaded version of Alpine Linux to it using `tar` similar to the following: <br /> `tar xzf alpine-rpi-3.8.0-aarch64.tar.gz -C /alpine/boot/partition/here`

4. Customize `answer-file.txt` and maybe `install.sh` to your liking and then copy the entire directory to the mounted boot partition.

5. Unmount the SD card or USB drive, insert it into the Raspberry Pi, and turn it on.

6. Log in to Alpine Linux once it has booted up. The user name to use is `root` and the password is empty.

7. Run `install.sh` similar to the following, paying close attention to the notes it displays: <br /> `/media/mmcblk0p1/install.sys/install.sh`.

8. Have fun.
