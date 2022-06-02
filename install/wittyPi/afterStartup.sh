#!/bin/bash
# file: afterStartup.sh
#
# This script will be executed in background after Witty Pi 3 gets initialized.
# If you want to run your commands after boot, you can place them here.
#
#
# WiiBee mount and autorun USB
#
USB_DEV=/dev/sda1
USB_MNT=/mnt/bee1
logger "Check if USB disk $USB_DEV is plugged in"
[ -e $USB_DEV ] && logger "mount $USB_DEV" || exit 1
#sudo mount -o uid=pi,gid=pi -o umask=000 $USB_DEV $USB_MNT
sudo mount $USB_DEV $USB_MNT
SCRIPT="autorun.sh"
USB_DIR="${USB_MNT}/wiibee"
[ -x "${USB_DIR}/${SCRIPT}" ] || exit 2

cd $USB_DIR

export WIIBEE_SHUTDOWN=1

export PATH="${USB_DIR}:${PATH}"

#git remote set-url origin git@github.com:yourgithubname/repo_name.git
#git remote -v &>> autorun.log

. $SCRIPT 2>> autorun.log
