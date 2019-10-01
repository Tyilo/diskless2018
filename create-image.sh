#!/bin/bash
set -x
set -euo pipefail

CHROOT="$PWD/chroot"
MNT_HOME="$PWD/mnt-home"
CUSTOM="$PWD/customization"
IMAGE="$PWD/image"

reset() {
  if mountpoint -q "$CHROOT/proc"; then
    umount -lq "$CHROOT/proc"
  fi
  rm --one-file-system -rf "$CHROOT"
}

setup_base() {
  debootstrap --arch amd64 disco "$CHROOT" http://dk.archive.ubuntu.com/ubuntu/

  env -i chroot "$CHROOT" /bin/su <<'EOF'
  set -x
  set -euo pipefail
  export DEBIAN_FRONTEND=noninteractive

  passwd -l root

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
  XKBLAYOUT="dk,us"
  XKBVARIANT=""
  XKBOPTIONS="grp:win_space_toggle"

  BACKSPACE="guess"
EOF2

  cat > etc/apt/sources.list <<EOF2
  deb http://dk.archive.ubuntu.com/ubuntu disco main universe
  deb http://security.ubuntu.com/ubuntu/ disco-security universe main
  deb http://dk.archive.ubuntu.com/ubuntu disco-updates universe main
EOF2

  apt-get update
  apt-get upgrade -y
  apt-get install -y \
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
    curl \
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
    gdb \
    indicator-application \
    indicator-power \
    indicator-sound \
    laptop-detect \
    mate-accessibility-profiles \
    mate-applet-appmenu \
    mate-desktop-environment-core \
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
    xbacklight

  # fwupdate-signed

  apt-get install -y nodm

  apt-get -y autoremove && apt-get clean && du -shx /

  useradd -m contest -s /bin/bash
EOF

  rsync -rptl "$CUSTOM/" "$CHROOT"

  env -i chroot "$CHROOT" /bin/su <<'EOF'
update-initramfs -u
EOF
}

install_langs() {
  mount -t proc proc "$CHROOT"/proc

  env -i chroot "$CHROOT" /bin/su <<'EOF'
  set -x
  set -euo pipefail
  export DEBIAN_FRONTEND=noninteractive

  # Needed to install java
  ulimit -n 10000

  # Already installed:
  # C, C++, Python 2, Python 3

  # C#
  apt-get install -y mono-mcs mono-runtime mono-devel

  # Cobol
  apt-get install -y gnucobol

  # Go
  apt-get install -y gccgo

  # Haskell
  apt-get install -y ghc

  # Java
  apt-get install -y openjdk-11-{jdk,jre} libopenjfx-java

  # JavaScript (Node.js)
  apt-get install -y nodejs

  # JavaScript (SpiderMonkey)
  # TODO

  # Kotlin
  curl -L https://github.com/JetBrains/kotlin/releases/download/v1.3.0/kotlin-compiler-1.3.0.zip -o /tmp/kotlin.zip
  unzip /tmp/kotlin.zip -d /opt
  rm /tmp/kotlin.zip

  for f in /opt/kotlinc/bin/*; do
    ln -s "$f" /usr/bin
  done

  # Common Lisp
  apt-get install -y sbcl

  # Objective-C
  apt-get install -y gnustep-devel

  # OCaml
  apt-get install -y ocaml

  # Pascal
  apt-get install -y fp-compiler

  # PHP
  apt-get install -y php

  # Prolog
  apt-get install -y swi-prolog

  # Ruby
  apt-get install -y ruby

  # Rust
  apt-get install -y rustc
EOF

  umount -lq "$CHROOT/proc"
}

install_editors() {
  env -i chroot "$CHROOT" /bin/su <<'EOF'
  # Kattis cli
  cd /opt
  git clone https://github.com/Kattis/kattis-cli

  # Editors
  apt-get install -y ubuntu-make
  IDES=(
    atom
    idea
    pycharm
    sublime-text
    visual-studio-code
  )
  for ide in "${IDES[@]}"; do
    echo -e /opt/"$ide"'\na' | umake ide "$ide"
  done

  apt-get remove -y ubuntu-make

  # BlueJ
  curl https://www.bluej.org/download/files/BlueJ-linux-421.deb -o /tmp/bluej.deb
  dpkg -i /tmp/bluej.deb
  rm /tmp/bluej.deb

  apt-get -y autoremove && apt-get clean && du -shx /

  dpkg-query -W --showformat='${Package} ${Version}\n' > home/contest/filesystem.manifest
EOF

  mv "$CHROOT"/home/contest/filesystem.manifest "$IMAGE"
}

create_squashfs() {
  time mksquashfs "$CHROOT" "$IMAGE"/filesystem.squashfs -noappend -e boot -e home/contest -e tmp -e proc
}

cp_kernel() {
  cp "$CHROOT"/boot/vmlinuz-*-generic "$IMAGE"/vmlinuz
  cp "$CHROOT"/boot/initrd.img-*-generic "$IMAGE"/initrd
}

create_homefs() {
  mkdir -p "$MNT_HOME"

  dd if=/dev/zero of="$IMAGE"/home.ext2 bs=1MiB count=512 status=progress
  mkfs.ext2 "$IMAGE"/home.ext2
  mount -t ext2 "$IMAGE"/home.ext2 "$MNT_HOME"

  rsync -a "$CHROOT"/home/contest "$MNT_HOME"

  umount "$MNT_HOME"
  rmdir "$MNT_HOME"
}

if [ $# -eq 1 ]; then
  eval $1
  exit
fi

reset
setup_base
install_langs
install_editors
create_squashfs
cp_kernel
create_homefs
