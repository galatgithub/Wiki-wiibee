#! /bin/bash

# Bluetooth MAC, use: hcitool scan, or: python wiiboard.py
BTADDR="00:00:00:00:00:00 00:00:00:00:00:00 00:00:00:00:00:00 00:00:00:00:00:00 00:00:00:00:00:00" 
# Bluetooth relays addresses
BTRLADDR="00:00:00:00:00:00 00:00:00:00:00:00 00:00:00:00:00:00 00:00:00:00:00:00 00:00:00:00:00:00" 

# Connexion cle 3G
# fix Huawei E3135 recognized as CDROM [sr0]
lsusb | grep 12d1:1f01 && sudo usb_modeswitch -v 0x12d1 -p 0x1f01 -M "55534243123456780000000000000a11062000000000000100000000000000"
# run DHCP client to get an IP
ifconfig -a | grep eth1 -A1 | grep inet || sudo dhclient eth1
sleep 10
lsusb | grep 12d1:1f01 && sudo usb_modeswitch -v 0x12d1 -p 0x1f01 -M "55534243123456780000000000000a11062000000000000100000000000000"
# run DHCP client to get an IP
ifconfig -a | grep eth1 -A1 | grep inet || sudo dhclient eth1
sleep 10

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

######## MULTIPLE WIIBOARDs #############################################

# Detection des relais

nb_wiiboard=$(echo "$BTADDR" | wc -w)
echo Expected wiiboards $nb_wiiboard
nb_counted=0
try=0
until [ $nb_counted -eq $nb_wiiboard -o $try -eq 10 ]; do
    ((try++))
    echo Search JDY devices...
    results=$(hcitool scan | grep -E "JDY*") 
    echo JDY found $results
    nb_counted=$(echo $results | grep -oE "JDY*" | wc -l)
    echo counted $nb_counted
    [ $nb_counted -ne $nb_wiiboard ] && { echo "restart BT"; sudo systemctl restart bluetooth; sleep 10; }
done

if [ $try -eq 10 ]; then
    echo "Problems : 10 attempts to restart bluetooth without response from all wiiboards, check wiiboards alimentation" #| mail -s "Wiibee_clone1 : Problem with wiiboard" guilhem.a@free.fr
fi

read -a strarr <<< "$results"

j=1
for i in $results; do
	if [ $((j++%2)) -eq 0 ]
	then
	  NAME+=("$i")
	else
	  MAC+=("$i")
	fi
done

BTRLADDR=""
j=0
for i in "${NAME[@]}"; do
	if [[ "$i" == *JDY* ]]
	then
	  BTRLADDR="$BTRLADDR ${MAC[$j]}"
	fi
	((j++))
done
BTRLADDR=${BTRLADDR:1}

echo "Relais detectes=${BTRLADDR[@]}"

# Switch on/off des relais

N=0
LOGFILE=""
for nbtrl in $BTRLADDR; do
#    echo $nbtrl
    FILE="/dev/rfcomm${N}"
    [ -f "$FILE" ] && { echo $(ls $FILE); } 
    [ ! -f "$FILE" ] && { echo "$FILE does not exist."; sudo rfcomm bind $N $nbtrl; sudo chmod o+rw /dev/rfcomm$N; }
    LOGFILE="$LOGFILE /dev/rfcomm$N"
    ((N++)) 
done

LOGFILE=${LOGFILE:1}
#echo "LOGFILE = ${LOGFILE[@]}"

open="\xA0\x01\x01\xA2"
for i in $LOGFILE; do
    echo "open $i"
    echo -e $open > "$i" & pidbt=$! &
#    sleep 1
done
sleep 5
kill $pidbt 2>/dev/null

close="\xA0\x01\x00\xA1"
for i in $LOGFILE; do
    echo "close $i"
    echo -e $close > "$i" & pidbt=$! &
#    sleep 1
done
sleep 5
kill $pidbt 2>/dev/null

#########################################################################

logger "Start listening to the mass measurements"
# replace python by python3
python autorun.py $BTADDR >> wiibee.txt
logger "Stopped listening"
python txt2js.py wiibee < wiibee.txt > wiibee.js
python txt2js.py wiibee_battery < wiibee_battery.txt > wiibee_battery.js

## send alert  if one of the wb < 4.5 volts
#flag_lowbat=($(awk -F " " 'END { for (i=2; i<=NF; i++) { print ($i<4.5) } }' wiibee_battery.txt))
#arr=($BTADDR)
#j=0
#for i in ${flag_lowbat[@]}; do
    #if [ $i -gt 0 ]
    #then
        #echo "Wiiboard ${arr[$j]} has low battery" | mail "Wiibee_clone2 : Problem with wiiboard" email@address.fr
    #fi
    #((j++))
#done

for i in $LOGFILE; do
    echo "close $i"
    echo -e $close > "$i" & pidbt=$! &
done
sleep 10
kill $pidbt 2>/dev/null

((N--))
for i in `seq 0 $N`; do
    sudo rfcomm release $i
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
