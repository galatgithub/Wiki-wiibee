#! /bin/bash

# Bluetooth MAC, use: hcitool scan, or: python wiiboard.py
# Balance installed : #2 Vert-jaune, var offset = -2.2 (à rajouter dans index.html) 
BTADDR="00:00:00:00:00:00"
# Bluetooth relays addresses
BTRLADDR="00:00:00:00:00:00"

## Connexion cle 3G
## fix Huawei E33531 recognized as CDROM [sr0]
#lsusb | grep 12d1:1f01 && sudo usb_modeswitch -v 0x12d1 -p 0x1f01 -M "55534243123456780000000000000a11062000000000000100000000000000"
## run DHCP client to get an IP
#ifconfig -a | grep eth1 -A1 | grep inet || sudo dhclient eth1
#sleep 10
#lsusb | grep 12d1:1f01 && sudo usb_modeswitch -v 0x12d1 -p 0x1f01 -M "55534243123456780000000000000a11062000000000000100000000000000"
## run DHCP client to get an IP
#ifconfig -a | grep eth1 -A1 | grep inet || sudo dhclient eth1
#sleep 10

#sleep 12 # FIXME "wait" for dhcpd timeout
# if BT failed: sudo systemctl status hciuart.service
hciconfig hci0 || hciattach /dev/serial1 bcm43xx 921600 noflow -

d0=$(date +%s)
until hciconfig hci0 up; do
    systemctl restart hciuart
    if [ $(($(date +%s) - d0)) -gt 20 ]; then
        echo "failed to bring up HCI, rebooting"
        /sbin/reboot
    fi
    sleep 1
done

logger "Simulate press red sync button on the Wii Board"

# Switch on bluetooth relay

######## SINGLE WIIBOARD ###############################################

#hcitool scan
#echo -ne "scan on" | bluetoothctl
#echo -ne "scan off" | bluetoothctl
#echo -ne "agent on" | bluetoothctl
#echo -ne "trust $BTRLADDR" | bluetoothctl
#echo -ne "pair $BTRLADDR" | bluetoothctl
sudo rfcomm bind 0 $BTRLADDR
sudo chmod o+rw /dev/rfcomm0
# switch ON
echo -e "\xA0\x01\x01\xA2" > /dev/rfcomm0 & pidbt=$!
sleep 5
kill -9 $pidbt 2>/dev/null

#switch OFF
echo -e "\xA0\x01\x00\xA1" > /dev/rfcomm0 & pidbt=$!
sleep 10
kill -9 $pidbt 2>/dev/null

logger "Start listening to the mass measurements"
# replace python by python3
python3 autorun.py $BTADDR >> wiibee.txt
logger "Stopped listening"
python txt2js.py wiibee < wiibee.txt > wiibee.js
python txt2js.py wiibee_battery < wiibee_battery.txt > wiibee_battery.js

# send alert if one of the wb < 4.5 volts
flag_lowbat=($(awk -F " " 'END { for (i=2; i<=NF; i++) { print ($i<4.5) } }' wiibee_battery.txt))
arr=($BTADDR)
j=0
for i in ${flag_lowbat[@]}; do
    if [ $i -gt 0 ] 
    then 
        echo "Wiiboard ${arr[$j]} has low battery" | mail -s "Wiibee1 : Problem with wiiboard" address@email.fr
    fi
    ((j++))
done

### git to github ##########################"

GIT=`which git`
REPO_DIR=/mnt/bee1/wiibee/
cd ${REPO_DIR}
${GIT} commit wiibee*.js wb_temperatures.txt autorun.log -m "[data] $(date -Is)"
${GIT} push origin master &>A

[ -z "$WIIBEE_SHUTDOWN" ] && exit 0
logger "Shutdown WittyPi"
# shutdown Raspberry Pi by pulling down GPIO-4
gpio -g mode 4 out
gpio -g write 4 0  # optional
logger "Shutdown Raspberry"
shutdown -h now # in case WittyPi did not shutdown
