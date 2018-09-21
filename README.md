Ubuntu Mint 18.04 image for NCPC 2018
=====================================

Goal: Create a bootable USB drive with Ubuntu Mint 18.04 configured for a programming contest.

* Auto-login
* Firefox homepage set to contest homepage on kattis.com
* Text editors and IDEs preinstalled (emacs, vim, nano, gedit, IntelliJ, PyCharm, VS Code, BlueJ)
* USB drive can be removed once the system has booted

System requirements:

* PC laptop (non-Mac) with 3 GB available space.
* Fast startup disabled in Windows
* Secure boot disabled

"Fast startup" in Windows must be disabled so that Linux can mount the NTFS partition.
Go to Control Panel, "Choose what the power buttons do", and disable "Turn on fast startup (recommended)".

Cheap USB drives typically cannot keep up with the I/Os required to run a
modern operating system. To resolve this issue, the live operating system first
copies itself to a partition on the laptop with enough available space to hold
the read-only system image (compressed size roughly 2 GB) and a writable home
partition (512 MB).

Installing the image to a USB drive
-----------------------------------

You need the following files in `image/`:

* image/CONTEST (empty)
* image/boot/grub/grub.cfg (198 B)
* image/filesystem.squashfs (2053 MB)
* image/home.ext2 (537 MB)
* image/initrd (50 MB)
* image/vmlinuz (8 MB)

Run `./dl.sh` to download the large files.

If the USB drive is at `/dev/sdx`, run the command:

```
sudo ./install-to-disk.sh /dev/sdx
```

The script takes about 2-6 minutes to run.

The script by default checks that the vendor and model of the USB drive is
recognized (to prevent accidentally overwriting a non-USB drive).
If the script complains that the vendor/model is incorrect, edit
`install-to-disk.sh` to add the vendor and model in the following section:

```
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
```


Running in an emulator
----------------------

To test the USB stick in QEmu, create an empty test disk in `test.img`
which is served as a block device at `/dev/loop0` by running `sudo ./setup-test-disk.sh`.

Then, assuming your USB stick is at `/dev/sdx`, run the following command:

```
xhost +; sudo qemu-system-x86_64 -enable-kvm -hda /dev/sda -hdb /dev/loop0 -m 2048 -vga std
```


Creating the image from scratch
-------------------------------

To create the image from scratch, you will need the `debootstrap` command
to install a fresh Ubuntu base image into a chroot.
The process should take you between 20 and 60 minutes,
depending on your hardware (network and storage speeds).

----

Create an empty directory and `cd` into it.
Then, run the following command
to install Ubuntu 18.04 (bionic) into a new subdirectory named `chroot`:

```
sudo debootstrap --arch amd64 bionic $PWD/chroot http://dk.archive.ubuntu.com/ubuntu/
```

(Remember to replace `dk.archive.ubuntu.com` with a mirror near you.)

----

For some reason, installing Java requires having `/proc` mounted inside the chroot.
Mount that with the command:

```
sudo mount -t proc proc chroot/proc
```

----

We will create the future contents of the USB drive inside `image`,
which we populate with the `boot/grub/grub.cfg` file and the empty `CONTEST` marker file.
We will also need `mnt-home` to mount the home partition, so create that now.

```
mkdir -p image/boot/grub mnt-home && touch image/CONTEST
cat > image/boot/grub/grub.cfg <<'EOF'
search --set=root --file /CONTEST

insmod all_video

set default="0"
set timeout=1

menuentry "Ubuntu 18.04 Contest Edition" {
    linux /vmlinuz boot=casper nomodeset noprompt
    initrd /initrd
}
EOF
```

----

The following commands are executed inside a chroot.
(If you are comfortable with `screen` or another terminal multiplexer, start it now.)
Start by running the command:

```
sudo chroot chroot bin/su
```

The first thing to do inside the chroot is to set the root password:

```
echo root:hunter2 | chpasswd
```

(Change `hunter2` with your preferred root password.)

Next, set up the locale, timezone and keyboard layout:

```
export TERM=xterm-256color; dpkg-reconfigure locales && dpkg-reconfigure tzdata && dpkg-reconfigure keyboard-configuration
```

We set the `TERM` environment variable since the chroot might not have the same
terminal definitions as your host system, but dpkg-reconfigure depends on
`TERM` being set to something sensible.

Next, we need to add the "universe" repository to download most interesting
software packages in Ubuntu. Open the `sources.list` file with `vi`:

```
vi etc/apt/sources.list
```

In vi, press `A` to append at the end of the line, type ` universe`, Escape, `:wq`, and Return.

Next, we install the packages we want. I have curated a list of packages
which should probably be trimmed down for the purposes of this guide,
but anyway here it is:

```
apt-get update && apt-get install linux-image-generic build-essential casper rsync git emacs nano vim-gtk3 mate-desktop-environment firefox xorg bc acl alsa-base anacron linux-sound-base mate-indicator-applet mate-indicator-applet-common pciutils poppler-utils pulseaudio pulseaudio-utils rfkill session-migration software-properties-common software-properties-gtk ssl-cert ubuntu-drivers-common ubuntu-sounds usbutils wget wireless-tools wpasupplicant network-manager network-manager-gnome network-manager-openvpn-gnome network-manager-pptp-gnome acpi-support appmenu-gtk2-module appmenu-gtk3-module exfat-fuse fwupd fwupdate fwupdate-signed gdb indicator-application indicator-power indicator-sound laptop-detect mate-accessibility-profiles mate-applet-appmenu mate-dock-applet mate-hud mate-menu mate-netbook mate-optimus mate-sensors-applet mate-tweak mate-window-buttons-applet mate-window-menu-applet mate-window-title-applet pm-utils ubuntu-mate-artwork libgconf-2-4 gconf-service python{,3}-{pip,setuptools} python{,3}-requests pypy clang gedit apport- grub-pc- blueman- thunderbird- unattended-upgrades-
```

The above list critically contains `casper`, which installs a bunch of scripts
in the initial ramdisk that are needed to boot a live system.

Note that we specifically ask apt-get not to install the following packages:
apport, grub-pc, blueman, thunderbird, unattended-upgrades;
because we do not want them in our live image.

Try running the following command if you are curious to see how much space your Ubuntu installation is taking up so far:

```
apt-get autoremove && apt-get clean && du -xsb
```

On my system, an image size of 3561229284 bytes (= 3.6 GB) is reported.

We want to login automatically, so install the `nodm` display manager:

```
apt-get install nodm
```

Note that nodm needs to be configured in `/etc/default/nodm`, but we do that later.

Add the live image user - in my image it's called `contest`:

```
adduser contest
```

Now we are ready to configure `casper` (to customize live image booting),
`nodm` (to set the autologin user to `contest`) and add a bunch of
desktop files in `/usr/share/applications` and scripts in `/usr/local/bin`.
Outside the chroot, run the following command:

```
sudo rsync -rptl ../customization/ chroot/
```

Since we have now configured `casper`, we need to recreate the initial ramdisk:

```
update-initramfs -u
```

If you placed any `deb` or `tar.gz` files in `customization/software`, install them now.
I ran the following commands to install Visual Studio Code, OpenJDK, BlueJ,
IntelliJ, PyCharm, and the Kattis command-line interface:

```
dpkg -i software/code_1.27.2-1536736588_amd64.deb
apt-get install openjdk-8-{jdk,jre} libopenjfx-java
dpkg -i software/BlueJ-linux-413.deb
(cd opt && tar xf ../software/ideaIC-2018.2.3-no-jdk.tar.gz && tar xf ../software/pycharm-community-2018.2.3.tar.gz && git clone https://github.com/Kattis/kattis-cli)
rm -rf software/
```

At this point, you may want to rerun the command from earlier to see the size of the image:

```
apt-get autoremove && apt-get clean && du -xsb
```

For me, the reported size was 5382296741 bytes (= 5.4 GB).

For future reference, you should dump the list of installed packages along with their versions:

```
dpkg-query -W --showformat='${Package} ${Version}\n' > home/contest/filesystem.manifest
```

Outside the chroot, move the file into `image/` with the command:

```
mv chroot/home/contest/filesystem.manifest image/
```

----

We have now installed Ubuntu Mint into `chroot/`. Outside the chroot,
we run the following command to compress `chroot/` into a read-only file system image:

```
time sudo mksquashfs $PWD/chroot $PWD/image/filesystem.squashfs -noappend -e boot -e home/contest -e tmp -e proc
```

This takes about 4 minutes on my laptop, so open another terminal and continue
running the following commands.

Copy the kernel and initial ramdisk into `image/`:

```
sudo cp chroot/boot/vmlinuz-4.15.0-20-generic image/vmlinuz && sudo cp chroot/boot/initrd.img-4.15.0-20-generic image/initrd
```

(Note, you might have to adjust the version numbers; `4.15.0-20` was the
current kernel in Ubuntu 18.04 when I wrote this guide.)

Create a new ext2 partition to serve as the home partition and mount it at `mnt-home`:

```
dd if=/dev/zero of=image/home.ext2 bs=1MiB count=512 && mkfs.ext2 image/home.ext2 && sudo mount -t ext2 image/home.ext2 mnt-home
```

At this point you can copy the contents of `/home/contest` in the chroot into the home partition:

```
sudo rsync -a chroot/home/contest mnt-home/
```

Alternatively, if you have other data to populate in `/home/contest`, do that now.

When you are done, unmount `mnt-home`:

```
sudo umount mnt-home
```

How it works
------------

Here's a broad overview of what happens at boot.

In `image/boot/grub/grub.cfg`, we have specified that the root filesystem
(that is, the USB stick)
should be found as the one containing a marker file named `CONTEST` in the root:

```
search --set=root --file /CONTEST
```

After 1 second, GRUB should load the kernel at `/vmlinuz` and the initial ramdisk at `/initrd`
and boot the kernel with the command line `boot=casper`:

```
set default="0"
set timeout=1

menuentry "Ubuntu 18.04 Contest Edition" {
    linux /vmlinuz boot=casper nomodeset noprompt
    initrd /initrd
}
```

In the initial ramdisk, the `casper` boot script runs
and eventually runs the premount shell script
`customization/usr/share/initramfs-tools/scripts/casper-premount/05contest`.

The premount script finds the USB stick by scanning all partitions
for the one containing the marker file `CONTEST` (just like GRUB did).
While scanning all partitions, it notes the non-`CONTEST` partition with the
most free space available.
After the scan, `filesystem.squashfs` and `home.ext2` are copied from the USB stick
to the partition with the most free space available
into a directory named after `$FLAVOUR`, specified in
`customization/etc/casper.conf`.
If during the partition scan, a partition is found with a directory named `$FLAVOUR`,
then that partition is used (instead of picking the one with the most free space).
If `filesystem.squashfs` and `home.ext2` already exist, they are not overwritten.
This saves time on subsequent boots (since copying the files can take a long time),
and it allows the home partition to persist between boots.

After running the premount script, `casper` mounts the local partition
to which the filesystem was copied and mounts `filesystem.squashfs`
as a unionfs with a writable ramdisk on top.

Later on during the boot process, `casper` runs the bottom script
`customization/usr/share/initramfs-tools/scripts/casper-bottom/02contest`,
which mounts `home.ext2` on `/home`.
