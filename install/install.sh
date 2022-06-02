#! /bin/bash
# After WittyPi3 install: http://www.uugear.com/product/witty-pi-3-mini-realtime-clock-and-power-management-for-raspberry-pi/
# cd; wget http://www.uugear.com/repo/WittyPi3/install.sh
# sudo sh install.sh
#cd; wget https://raw.githubusercontent.com/galatgithub/Wiki-wiibee/main/install.sh
#sudo sh install.sh
USB_DEV=/dev/sda1
USB_MNT=/mnt/bee1
python -c'import bluetooth' 2>/dev/null || apt-get install python-bluez
echo "Check if USB disk $USB_DEV is plugged in"
[ -e $USB_DEV ] || exit 1
[ -d $USB_MNT ] || mkdir -p $USB_MNT
mount -o uid=pi,gid=pi $USB_DEV $USB_MNT
cd $USB_MNT

echo "How many balance you want to connect"
echo "1 - One"
echo "2 - Two to five"
read choice;
mkdir wiibee
case $choice in
  1) wget https://raw.githubusercontent.com/galatgithub/Wiki-wiibee/main/install/single-balance/single-balance.tar.xz; tar -xf single-balance.tar.xz -C ./wiibee/; rm single-balance.tar.xz;;
  2) wget https://raw.githubusercontent.com/galatgithub/Wiki-wiibee/main/install/multi-balance/multi-balance.tar.xz; tar -xf multi-balance.tar.xz -C ./wiibee/; rm multi-balance.tar.xz;;
  *) echo "This choice is not available. Please choose a different one.";; 
esac
cd wiibee
wget https://raw.githubusercontent.com/galatgithub/Wiki-wiibee/main/install/wiiboard.py
wget https://raw.githubusercontent.com/galatgithub/Wiki-wiibee/main/install/init_BT_relay.sh

# touch wiibee.js; git add wiibee.js
# git commit wiibee.js -m"[data] first commit $(date -Is)"
# TODO setup a new ssh key between the Raspberry and GitHub
# https://help.github.com/articles/generating-an-ssh-key/
# https://www.raspberrypi.org/documentation/remote-access/ssh/passwordless.md

wget https://raw.githubusercontent.com/galatgithub/Wiki-wiibee/main/install/wittyPi/schedule.wpi -P ~/wittyPi/schedules/
wget https://raw.githubusercontent.com/galatgithub/Wiki-wiibee/main/install/wittyPi/afterStartup.sh -P ~/wittyPi/

echo "You can now select the wiibee schedule script..."
/home/pi/wittyPi/wittyPi.sh
# TODO fix: Bluetooth failed: sudo systemctl status hciuart.service
# try apt-get install raspberrypi-sys-mods
# try apt-get install --reinstall pi-bluetooth

/home/pi/wittyPi/wittyPi.sh
# TODO fix: Bluetooth failed: sudo systemctl status hciuart.service
# try apt-get install raspberrypi-sys-mods
# try apt-get install --reinstall pi-bluetooth
