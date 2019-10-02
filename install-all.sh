#!/bin/bash

set -euo pipefail
set -o nullglob

is_done() {
	dev="$1"
	part="${dev}3"

	if [ ! -e "$part" ]; then
		return 1
	fi

	dir=$(mktemp -d)

	if ! mount "$part" "$dir"; then
		return 1
	fi
	
	res=1
	if [ -e "$dir/filesystem.squashfs" ] && [ -e "$dir/home.ext2" ]; then
		res=0
	fi
	
	umount -lq "$dir"

	rmdir "$dir"

	return $res
}

while true; do
	for d in /dev/sd?; do
		DISK="${d#/dev/}"
		if [ ! -e "mnt-$DISK" ]; then
			if is_done "$d"; then
				echo -n "$d is done, please plug in new"
				read
			else
				echo "Installing on $d"
				./install-to-disk.sh "$d" &
			fi
		fi
	done

	sleep 1
done

./install-to-disk.sh /dev/sd

