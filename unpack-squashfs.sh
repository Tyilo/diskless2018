#!/bin/sh

set -euo pipefail

if [ "$#" -ne 2 ]; then
	echo "Usage: $0 <image> <dest>"
	echo "Unpacks the squashfs at <image> into directory <dest>"
	exit 1
fi

case "$2" in
	*/)
		echo "$2: No trailing slash allowed"
		exit 1
		;;
esac

mkdir -p "$2" "$2-mnt"
mount "$1" "$2-mnt"
rsync -a "$2-mnt/" "$2/"
umount "$2-mnt"
rmdir "$2-mnt"
