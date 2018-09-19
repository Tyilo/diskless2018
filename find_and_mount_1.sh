#!/bin/sh
# vim:set ft=sh sw=4 et:

. /scripts/casper-functions
. /scripts/casper-helpers

# The following is not exported from casper
mountpoint=/cdrom

# casper seems to be uncertain whether the variables in casper.conf must
# be exported or not. We need $FLAVOUR.
[ -f /etc/casper.conf ] && . /etc/casper.conf

find_and_allocate() {
    # Either panics, or mounts a local partition on /mnt/apartment
    # where "/mnt/apartment/$FLAVOUR.ext3" exists.

    # We need to copy over ${mountpoint}. How large a backing file should we create?
    countK=$(fs_size "" "${mountpoint}" "used")
    countK=$(expr ${countK} + ${countK} / 5 ) # 20% more to be sure
    countM=$(expr ${countK} / 1024)

    # Scan all partitions and find the one with an existing $FLAVOUR.ext3
    # or the one with the most free space.
    bestfreespace=0
    bestdevname=
    for sysblock in $(echo /sys/block/* | tr ' ' '\n' | grep -v loop); do
        n=${sysblock##*/}
        if [ "${n#fd}" != "$n" ]; then
            # Do not probe floppies
            continue
        fi
        for dev in $(subdevices "${sysblock}"); do
            devname=$(sys2dev "${dev}")
            [ "$quiet" = "y" ] || printf "${devname}:"
            fstype=$(get_fstype "${devname}")
            [ "$quiet" = "y" ] || printf " (${fstype})"
            if ! is_supported_fs ${fstype}; then
                [ "$quiet" = "y" ] || printf " filesystem not supported\n"
                continue
            fi
            if where_is_mounted "${devname}" > /dev/null; then
                [ "$quiet" = "y" ] || printf " already mounted - skip\n"
                continue
            fi

            mountp="/mnt/apartment"
            mkdir -p "${mountp}"
            mount -t "$fstype" -o rw "${devname}" "${mountp}"
            if [ "$?" -eq 0 ]; then
                if [ -e "${mountp}/$FLAVOUR.ext3" ];
                    [ "$quiet" = "y" ] || printf " contains $FLAVOUR.ext3 - return\n"
                    # Success: We found a previously used partition.
                    return 0
                fi
                freespace=$(fs_size "" "${mountp}")
                [ "$quiet" = "y" ] || printf " ${freespace} K available\n"
                if [ "$freespace" -gt "$bestfreespace" ]; then
                    bestfreespace="$freespace"
                    bestdevname="$devname"
                fi
                umount "${mountp}"
            else
                [ "$quiet" = "y" ] || printf " could not mount - skip\n"
            fi
            rmdir "${mountp}"
        done
    done

    [ "$bestfreespace" -eq 0 ] && panic "Could not find any suitable local partition!"
    [ "$bestfreespace" -lt "$countK" ] && panic "No suitable local partition has $countK K free space!"

    # Success: We found a partition with enough space. Create $FLAVOUR.ext3.
    [ "$quiet" = "y" ] || printf "Begin: Mount and allocate on ${bestdevname}\n"
    mountp="/mnt/apartment"
    mkdir -p "${mountp}"
    mount -t "$fstype" -o rw "${bestdevname}" "${mountp}" || panic "Could not mount ${bestdevname}"
    dd if=/dev/zero of="${mountp}/$FLAVOUR.ext3" bs=1M count="$countM" || panic "Could not dd ${countM} M to ${bestdevname}"
    mkfs.ext3 "${mountp}/$FLAVOUR.ext3" || panic "Could not mkfs.ext3 on ${bestdevname}"
    [ "$quiet" = "y" ] || printf "Done: Mount and allocate on ${bestdevname}\n"
    return 0
}

find_and_allocate
loopdevname=$(setup_loop "/mnt/apartment/$FLAVOUR.ext3" "loop" "/sys/block/loop*")
mkdir -p /mnt/apartment-tmp
mount "${loopdevname}" /mnt/apartment-tmp
