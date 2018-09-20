#!/bin/sh

set -euo pipefail

if [ "$#" -eq 0 ]; then
	echo "Usage: $0 /dev/sdx"
	echo "Replace x with the letter of the USB drive"
	exit 1
fi
case "$1" in
	/dev/sd?)
		DISK="${1#/dev/}"
		;;
	*)
		echo "Usage: $0 /dev/sdx"
		echo "Replace x with the letter of the USB drive"
		exit 1
		;;
esac

mkdir -p mnt-$DISK/efi mnt-$DISK/usb

ACTUAL_VENDOR=`cat /sys/class/block/$DISK/device/vendor`
ACTUAL_MODEL=`cat /sys/class/block/$DISK/device/model`
case "$ACTUAL_VENDOR" in
	"Teclast "|"UDISK   ")
		;;
	*)
		echo "$DISK: Unrecognized vendor '$ACTUAL_VENDOR'"
		exit 1
		;;
esac
case "$ACTUAL_MODEL" in
	"CoolFlash USB3.0"|'USB 3.0         ')
		;;
	*)
		echo "$DISK: Unrecognized model '$ACTUAL_MODEL'"
		exit 1
		;;
esac

if `mount | grep -q /dev/$DISK`; then
	echo "$DISK appears to be mounted!"
	exit 1
fi

parted --script "/dev/$DISK" \
	mklabel gpt \
	mkpart primary fat32 1MiB 2MiB \
	name 1 BIOS \
	'set' 1 bios_grub on \
	mkpart ESP fat32 2MiB 202MiB \
	name 2 EFI \
	'set' 2 esp on \
	mkpart primary fat32 202MiB 100% \
	name 3 CONTEST \
	'set' 3 msftdata on
gdisk "/dev/$DISK" << EOF
r     # recovery and transformation options
h     # make hybrid MBR
1 2 3 # partition numbers for hybrid MBR
N     # do not place EFI GPT (0xEE) partition first in MBR
EF    # MBR hex code
N     # do not set bootable flag
EF    # MBR hex code
N     # do not set bootable flag
83    # MBR hex code
Y     # set the bootable flag
x     # extra functionality menu
h     # recompute CHS values in protective/hybrid MBR
w     # write table to disk and exit
Y     # confirm changes
EOF
mkfs.vfat -F32 "/dev/${DISK}2"
mkfs.vfat -F32 "/dev/${DISK}3"
mount "/dev/${DISK}2" mnt-$DISK/efi
mount "/dev/${DISK}3" mnt-$DISK/usb
grub-install --target=x86_64-efi --efi-directory=mnt-$DISK/efi --boot-directory=mnt-$DISK/usb/boot --removable --recheck
grub-install --target=i386-pc --boot-directory=mnt-$DISK/usb/boot --recheck "/dev/$DISK"
time rsync -r image/ mnt-$DISK/usb/
time umount mnt-$DISK/usb mnt-$DISK/efi
