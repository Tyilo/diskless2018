Future work (after 2018)
========================

* Install NVIDIA drivers on image!

* Configuration in CONTEST file (instead of /etc/casper.conf)

* Use .disk/info file instead of setting FLAVOUR manually

* Look into the debconf-copydb stuff that casper is doing

* Support Mac HFS+ and APFS filesystems somehow

* Create a script to run apt-get update,upgrade,autoremove,clean and remake the squashfs

* Copy over a directory on the USB drive to /home/contest on every boot to allow adding files in the last minute, e.g. sample inputs and outputs.

Configuring /home
-----------------

Rather than booting into the image and configuring /home manually, it would be nice to control everything from a configuration file:

* Firefox homepage

* Firefox bookmarks

* Launchers on desktop

* Disabling screensaver

* Aliases in .bashrc to set keyboard layout

Unattended install script
-------------------------

The following things can probably be done with a script instead of manual menuing:

* Configuration of packages locales, tzdata, keyboard-configuration, nodm

Running in RAM
--------------

If no suitable local partition is found, but there is enough RAM,
consider copying the squashfs to a ramdisk and mounting that.

Maybe periodically copy non-dotfiles from /home/contest to USB drive
instead of mounting USB drive directly on /home.
