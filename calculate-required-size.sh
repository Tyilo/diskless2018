#!/bin/sh
IMAGE="image"

image_size=$(du -ks "$IMAGE/filesystem.squashfs" | cut -f1)
home_size=$(du -ks "$IMAGE/home.ext2" | cut -f1)
total_size=$(expr ${image_size} + ${home_size})
total_size=$(expr ${total_size} + ${total_size} / 20) # 5% more to be sure
total_mb=$(expr ${total_size} / 1024)

echo "Total MB: $total_mb"
