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

is_ro_mount() {
    mountp="$1"
    mount_options=$(grep "^${mountp} " /proc/mounts | cut -d' ' -f4)
    case ",$mount_options," in
        *,rw,*)
            return 1
            ;;
        *,ro,*)
            return 0
            ;;
        *)
            # Hmm, neither rw nor ro? Probably not read-only
            return 1
    esac
}

[ -z "$FLAVOUR" ] && panic "No \$FLAVOUR set!"

USB_IMAGE_MARKER=CONTEST

# Note: One mountpoint must not be a prefix of another,
# since fs_size uses `df -k | grep -s $mountp` to determine free space.
MOUNTP_CONTEST_TMP="/mnt/contest-tmp"
MOUNTP_IMAGE="/mnt/contest-image"
MOUNTP_LOCAL="/mnt/contest-local"

mkdir -p $MOUNTP_CONTEST_TMP $MOUNTP_IMAGE $MOUNTP_LOCAL

bestfreespace=0
bestdevname=
image_part=
local_part=
ro_ntfs=

search_partitions() {
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

        mount -t "$fstype" -o rw "${devname}" "${MOUNTP_CONTEST_TMP}"
        if [ "$?" -eq 0 ]; then
            if [ -e "${MOUNTP_CONTEST_TMP}/$USB_IMAGE_MARKER" ]; then
                [ "$quiet" = "y" ] || printf " contains $USB_IMAGE_MARKER\n"
                image_part=$devname
                mount -o move "${MOUNTP_CONTEST_TMP}" "${MOUNTP_IMAGE}"
            elif [ "$fstype" == "ntfs" ] && is_ro_mount "${MOUNTP_CONTEST_TMP}"; then
                # Mountpoint is read-only NTFS.
                ro_ntfs="${devname}"
                umount "${MOUNTP_CONTEST_TMP}"
            elif [ -e "${MOUNTP_CONTEST_TMP}/$FLAVOUR" ]; then
                [ "$quiet" = "y" ] || printf " contains $FLAVOUR\n"
                # TODO: Verify that the files are actually there.
                local_part=$devname
                mount -o move "${MOUNTP_CONTEST_TMP}" "${MOUNTP_LOCAL}"
            else
                freespace=$(fs_size "" "${MOUNTP_CONTEST_TMP}")
                [ "$quiet" = "y" ] || printf " ${freespace} K available\n"
                if [ "$freespace" -gt "$bestfreespace" ]; then
                    bestfreespace="$freespace"
                    bestdevname="$devname"
                    bestdevfstype="$fstype"
                fi
                umount "${MOUNTP_CONTEST_TMP}"
            fi
        else
            [ "$quiet" = "y" ] || printf " could not mount - skip\n"
        fi
        if [ -n "${image_part}" -a -n "${local_part}" ]; then
            break
        fi
    done
    if [ -n "${image_part}" -a -n "${local_part}" ]; then
        break
    fi
done
}

prev_quiet=$quiet
for i in `range 1 15`; do
    search_partitions
    if [ -n "${image_part}" ]; then
        break
    fi
    sleep 1
    quiet=y
done
quiet=$prev_quiet

[ -z "${image_part}" ] && panic "Could not find the USB stick!"

if [ -z "${local_part}" ]; then

    # We need to copy over ${mountpoint}. How large a backing file should we create?

    image_size=$(du -ks "${MOUNTP_IMAGE}/filesystem.squashfs" | cut -f1)
    home_size=$(du -ks "${MOUNTP_IMAGE}/home.ext2" | cut -f1)
    total_size=$(expr ${image_size} + ${home_size})
    total_size=$(expr ${total_size} + ${total_size} / 20) # 5% more to be sure
    total_mb=$(expr ${total_size} / 1024)

    if [ "$bestfreespace" -lt "$total_size" ]; then
        if [ -n "${ro_ntfs}" ]; then
            echo
            echo
            echo
            echo "One of your NTFS partitions (${ro_ntfs}) was write-protected,"
            echo "probably because \"Fast startup\" is enabled in Windows."
            echo
            echo "Go to \"Choose what the power buttons do\" in Control Panel"
            echo "and disable \"Turn on fast startup (recommended)\" and try again."
            echo
            echo
            echo
        fi
        panic "No suitable local partition has $total_size K free space!"
    fi

    # Success: We found a partition with enough space. Create $FLAVOUR directory.
    [ "$quiet" = "y" ] || printf "Begin: Mount and allocate on ${bestdevname}\n"
    mountp="/mnt/apartment"
    mkdir -p "${mountp}"
    mount -t "${bestdevfstype}" -o rw "${bestdevname}" "${MOUNTP_LOCAL}" || panic "Could not mount ${bestdevname}"
    local_part="${bestdevname}"
    mkdir "${MOUNTP_LOCAL}/$FLAVOUR" || panic "Could not create directory $FLAVOUR"
    echo "Copying contest image filesystem for the first boot... This may take a while ($total_mb MB)"
    cp "${MOUNTP_IMAGE}/filesystem.squashfs" "${MOUNTP_LOCAL}/$FLAVOUR/filesystem.squashfs" || panic "Failed to copy filesystem.squashfs"
    cp "${MOUNTP_IMAGE}/home.ext2" "${MOUNTP_LOCAL}/$FLAVOUR/home-image" || panic "Failed to copy home.ext2"
    [ "$quiet" = "y" ] || printf "Done: Mount and allocate on ${bestdevname}\n"
fi

echo "export LIVEMEDIA=$local_part" >> /conf/param.conf
echo "export LIVE_MEDIA_PATH=$FLAVOUR" >> /conf/param.conf
umount "${MOUNTP_LOCAL}"
umount "${MOUNTP_IMAGE}"

# Everywhere in casper, modprobe is invoked via
# modprobe "${MP_QUIET}" ...
# This fails if $MP_QUIET is empty. Set it to -q to make things work.
echo "export MP_QUIET=-q" >> /conf/param.conf

echo "It is now safe to remove the contest USB stick"
