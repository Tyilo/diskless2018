#!/bin/sh

set -euo pipefail

dd if=/dev/zero of=test.img bs=1M count=10240
LOOPDEV=$(losetup -f --show test.img)

parted --script "$LOOPDEV" \
	mklabel gpt \
	mkpart primary fat32 1MiB 10% \
	mkpart primary ntfs 10% 80% \
	mkpart primary ext4 80% 100%
mkfs.vfat -F32 "${LOOPDEV}p1"
mkfs.ntfs "${LOOPDEV}p2"
mkfs.ext4 "${LOOPDEV}p3"

echo Initialized test.img with three partitions on $LOOPDEV
