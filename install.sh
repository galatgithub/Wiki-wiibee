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
case $choice in
  1) git clone https://github.com/galatgithub/wiibee.git; cd wiibee;;
  2) git clone https://github.com/galatgithub/wiibee_clone2; mv wiibee_clone2 wiibee; cd wiibee;;
  *) echo "This choice is not available. Please choose a different one.";; 
esac
wget https://raw.githubusercontent.com/galatgithub/wiibee/master/wiiboard.py

# touch wiibee.js; git add wiibee.js
# git commit wiibee.js -m"[data] first commit $(date -Is)"
# TODO setup a new ssh key between the Raspberry and GitHub
# https://help.github.com/articles/generating-an-ssh-key/
# https://www.raspberrypi.org/documentation/remote-access/ssh/passwordless.md
git remote add ssh git@github.com:galatgithub/wiibee_clone1.git
cp wittyPi/schedule.wpi /home/pi/wittyPi/schedules/wiibee.wpi
cp wittyPi/afterStartup.sh /home/pi/wittyPi/
echo "You can now select the wiibee schedule script..."
/home/pi/wittyPi/wittyPi.sh
# TODO fix: Bluetooth failed: sudo systemctl status hciuart.service
# try apt-get install raspberrypi-sys-mods
# try apt-get install --reinstall pi-bluetooth
