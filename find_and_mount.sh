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

mountpoint=/cdrom

# casper seems to be uncertain whether the variables in casper.conf must
# be exported or not. We need $FLAVOUR.
[ -f /etc/casper.conf ] && . /etc/casper.conf
