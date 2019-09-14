#!/bin/sh
cd image && curl -O \
	https://users-cs.au.dk/rav/diskless2018/image/filesystem.squashfs

# au306325@tildefiles:~$ find  public_html/diskless2018/image/ -ls
# 12953327908     40 drwxr-xr-x   3 au306325 www-data      121 Feb  8  2019 public_html/diskless2018/image/
# 12954557636 1250432 -rw-r--r--   1 au306325 www-data 1063485440 Feb  8  2019 public_html/diskless2018/image/filesystem.squashfs
# 12953328311     192 -rw-r--r--   1 au306325 www-data      39809 Sep 20  2018 public_html/diskless2018/image/filesystem.manifest
# 12953327909      40 drwxr-xr-x   3 au306325 www-data         22 Feb  8  2019 public_html/diskless2018/image/boot
# 12954557236      40 drwxr-xr-x   2 au306325 www-data          0 Sep 20  2018 public_html/diskless2018/image/boot/grub
# 12955122620      32 -rw-r--r--   1 au306325 www-data          0 Sep 20  2018 public_html/diskless2018/image/CONTEST
