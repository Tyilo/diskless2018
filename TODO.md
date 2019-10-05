Future work (after 2019)
========================

* Add a password to the contest user, if the user manages to logout.

* Fix that screen brightness can't be adjusted.

* Fix HiDPI displays.

* Support external monitors.

* Install NVIDIA drivers on image!

* Configuration in CONTEST file (instead of /etc/casper.conf)

* Use .disk/info file instead of setting FLAVOUR manually

* Look into the debconf-copydb stuff that casper is doing

* Support Mac HFS+ and APFS filesystems somehow

* Create a script to run apt-get update,upgrade,autoremove,clean and remake the squashfs

* Copy over a directory on the USB drive to /home/contest on every boot to allow adding files in the last minute, e.g. sample inputs and outputs.

* Use signed Ubuntu kernel to avoid having to disable Secure boot

Configuring /home
-----------------

Rather than booting into the image and configuring /home manually, it would be nice to control everything from a configuration file:

* Firefox homepage

* Firefox bookmarks

* Disabling screensaver (not using qemu and with a laptop on battery power)

Running in RAM
--------------

If no suitable local partition is found, but there is enough RAM,
consider copying the squashfs to a ramdisk and mounting that.

Maybe periodically copy non-dotfiles from /home/contest to USB drive
instead of mounting USB drive directly on /home.
