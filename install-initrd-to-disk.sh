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

mount "/dev/${DISK}3" mnt-$DISK/usb
time cp image/initrd mnt-$DISK/usb/initrd
sleep 1
time umount mnt-$DISK/usb
