#!/bin/sh
# vim:set ft=sh sw=4 et:

PREREQ=""

prereqs()
{
       echo "$PREREQ"
}

case $1 in
# get pre-requisites
prereqs)
       prereqs
       exit 0
       ;;
esac

. /scripts/casper-functions
. /scripts/casper-helpers

[ -z "$FLAVOUR" ] && panic "No \$FLAVOUR set!"

[ "$quiet" = "y" ] || printf "Mount home-image on /home..."
mount -o remount,rw /cdrom || panic "Couldn't remount /cdrom read-write"
HOME_LOOP=$(setup_loop "/cdrom/$FLAVOUR/home-image" "loop" "/sys/block/loop*")
if [ "$?" -ne 0 ]; then
    panic "setup_loop failed"
fi
mount -o rw -t ext2 "${HOME_LOOP}" /root/home || panic "Failed to mount /home"
