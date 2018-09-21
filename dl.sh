#!/bin/sh
cd image && curl -O \
	https://users-cs.au.dk/rav/diskless2018/image/filesystem.squashfs
	https://users-cs.au.dk/rav/diskless2018/image/home.ext2
	https://users-cs.au.dk/rav/diskless2018/image/initrd
	https://users-cs.au.dk/rav/diskless2018/image/vmlinuz
