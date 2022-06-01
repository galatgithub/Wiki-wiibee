#!/bin/bash

hcitool scan
echo -ne "scan on" | bluetoothctl
echo -ne "scan off" | bluetoothctl

echo "Enter MAC address (Example : 85:58:0E:16:73:EF):"
read BTRLADDR;

{
printf 'agent on\n\n'
sleep 2
printf "trust ${BTRLADDR}\n\n"
sleep 2
printf "pair ${BTRLADDR}\n\n"  
} | bluetoothctl

# Switch on/off des relais

sudo rfcomm bind 0 $BTRLADDR

sudo chmod o+rw /dev/rfcomm0

for i in 1 2 3 4; do

echo -ne "\xA0\x01\x01\xA2" > /dev/rfcomm0 & pidbt=$!

sleep 5
kill $pidbt 2>/dev/null

echo -ne "\xA0\x01\x00\xA1" > /dev/rfcomm0 & pidbt=$!

sleep 5
kill $pidbt 2>/dev/null
done

sudo rfcomm release 0

#~ **********************************************************
#~ echo -ne "agent on" | bluetoothctl

#~ echo -ne "trust 85:58:0E:16:73:EF" | bluetoothctl

#~ echo -ne "pair 85:58:0E:16:73:EF" | bluetoothctl

#~ sudo rfcomm bind 0 $BTRLADDR

#~ sudo chmod o+rw /dev/rfcomm0

#~ ls -l /dev/rfcomm0

#~ for i in 1 2 3 4; do

#~ echo -ne "\xA0\x01\x01\xA2" > /dev/rfcomm0 & pidbt=$!

#~ sleep 10
#~ kill $pidbt 2>/dev/null

#~ echo -ne "\xA0\x01\x00\xA1" > /dev/rfcomm0 & pidbt=$!

#~ sleep 1
#~ kill $pidbt 2>/dev/null
#~ done
