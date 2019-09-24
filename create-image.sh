#!/bin/bash
set -euo pipefail

CHROOT="$PWD/chroot"
MNT_HOME="$PWD/mnt-home"
CUSTOM="$PWD/customization"
IMAGE="$PWD/image"

sudo umount -q "$CHROOT/proc" || true
sudo rm -rf "$CHROOT"

mkdir "$CHROOT"
sudo debootstrap --arch amd64 bionic "$CHROOT" http://dk.archive.ubuntu.com/ubuntu/

echo bbbb

sudo mount -t proc proc "$CHROOT"/proc

echo aaa

mkdir -p "$MNT_HOME"

echo bb

sudo env -i chroot "$CHROOT" /bin/su <<'EOF'
set -x
set -euo pipefail

export TERM=xterm-256color
echo root:hunter2 | chpasswd

echo "locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8" | debconf-set-selections
echo "locales locales/default_environment_locale select en_US.UTF-8" | debconf-set-selections
rm /etc/locale.gen
dpkg-reconfigure -f noninteractive locales

TZ="Europe/Copenhagen"
echo "$TZ" > /etc/timezone 
ln -fs /usr/share/zoneinfo/"$TZ" /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

cat > /etc/default/keyboard <<EOF2
XKBMODEL="pc105"
XKBLAYOUT="us,dk"
XKBVARIANT=""
XKBOPTIONS="grp:win_space_toggle"

BACKSPACE="guess"
EOF2

cat > etc/apt/sources.list <<EOF2
deb http://dk.archive.ubuntu.com/ubuntu bionic main universe
deb http://security.ubuntu.com/ubuntu/ bionic-security universe main
deb http://dk.archive.ubuntu.com/ubuntu bionic-updates universe main
EOF2

apt-get update && apt-get install -y \
  linux-image-generic \
  build-essential \
  casper \
  rsync \
  git \
  emacs \
  nano \
  vim-gtk3 \
  mate-desktop-environment \
  firefox \
  xorg \
  bc \
  acl \
  alsa-base \
  anacron \
  linux-sound-base \
  mate-indicator-applet \
  mate-indicator-applet-common \
  pciutils \
  poppler-utils \
  pulseaudio \
  pulseaudio-utils \
  rfkill \
  session-migration \
  software-properties-common \
  software-properties-gtk \
  ssl-cert \
  ubuntu-drivers-common \
  ubuntu-sounds \
  usbutils \
  wget \
  wireless-tools \
  wpasupplicant \
  network-manager \
  network-manager-gnome \
  network-manager-openvpn-gnome \
  network-manager-pptp-gnome \
  acpi-support \
  appmenu-gtk2-module \
  appmenu-gtk3-module \
  exfat-fuse \
  fwupd \
  fwupdate \
  fwupdate-signed \
  gdb \
  indicator-application \
  indicator-power \
  indicator-sound \
  laptop-detect \
  mate-accessibility-profiles \
  mate-applet-appmenu \
  mate-dock-applet \
  mate-hud \
  mate-menu \
  mate-netbook \
  mate-optimus \
  mate-sensors-applet \
  mate-tweak \
  mate-window-buttons-applet \
  mate-window-menu-applet \
  mate-window-title-applet \
  pm-utils \
  ubuntu-mate-artwork \
  libgconf-2-4 \
  gconf-service \
  python{,3}-{pip,setuptools} \
  python{,3}-requests \
  pypy \
  clang \
  gedit \
  command-not-found \
  xbacklight \
  apport- \
  grub-pc- \
  blueman- \
  thunderbird- \
  unattended-upgrades-

apt-get -y autoremove && apt-get clean && du -shx

DEBIAN_FRONTEND=noninteractive apt-get install -y nodm

useradd -m contest

update-initramfs -u
EOF

sudo rsync -rptl "$CUSTOM/" "$CHROOT"

sudo env -i chroot "$CHROOT" /bin/su <<'EOF'
set -x
set -euo pipefail

# Fails due to ca-certificates-java (out of memory)
#apt-get install openjdk-8-{jdk,jre} libopenjfx-java

apt-get -y autoremove && apt-get clean && du -shx

dpkg-query -W --showformat='${Package} ${Version}\n' > home/contest/filesystem.manifest
EOF

mv "$CHROOT"/home/contest/filesystem.manifest "$IMAGE"

time sudo mksquashfs "$CHROOT" "$IMAGE"/filesystem.squashfs -noappend -e boot -e home/contest -e tmp -e proc

sudo cp "$CHROOT"/boot/vmlinuz-*-generic "$IMAGE"/vmlinuz
sudo cp "$CHROOT"/boot/initrd.img-*-generic "$IMAGE"/initrd

dd if=/dev/zero of="$IMAGE"/home.ext2 bs=1MiB count=512
mkfs.ext2 "$IMAGE"/home.ext2
sudo mount -t ext2 "$IMAGE"/home.ext2 "$MNT_HOME"

sudo rsync -a "$CHROOT"/home/contest "$MNT_HOME"

sudo umount "$MNT_HOME"
