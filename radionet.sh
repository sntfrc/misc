#!/bin/bash

### RadioNet -- automatic IP over AX.25 configuration script
### (C) 2023 Federico Santandrea
###
### Best used with a CM108 USB audio device with PTT mod.
#

# Print usage

if [ "$*" == "stop" ]; then
	killall direwolf
	exit 0
fi

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
	echo "syntax: $0 CALLSIGN IP_ADDRESS [speed]      (to start)" > /dev/stderr
	echo "        $0 stop                             (to stop)" > /dev/stderr
	exit 1
fi

# Prepare settings
# Change AUDIO_DEVICE to "default" to use main sound card (with VOX PTT).
AUDIO_DEVICE=CM108

CALLSIGN=$1
IP_ADDRESS=$2
SPEED=1200

if [ $# -eq 3 ]; then
	SPEED=$3
fi

# Install required tools
# (but you would be better off installing direwolf from GitHub before)

sudo -v

if [ ! -f "$(which direwolf)" ]; then
	sudo apt install -y direwolf
fi

if [ ! -f "$(which kissattach)" ]; then
	sudo apt install -y ax25-tools
fi

# Kill modem if it's already running

killall direwolf 2>/dev/null
sleep 1

# Prepare configuration files

if ! grep -q $CALLSIGN "/etc/ax25/axports"; then
	echo -e "\n$CALLSIGN\t$CALLSIGN\t0\t255\t7\tRadioNet" | sudo tee -a /etc/ax25/axports > /dev/null
fi

echo -e "ADEVICE $AUDIO_DEVICE\nMODEM $SPEED\nPTT CM108\n" > /tmp/direwolf.conf

# Run modem in background with pseudo-terminal support

direwolf -c /tmp/direwolf.conf -p &
sleep 1
rm /tmp/direwolf.conf

# Attach IP interface and fix KISS parameters

sudo kissattach $(readlink /tmp/kisstnc) $CALLSIGN $IP_ADDRESS
sudo kissparms -c 1 -p $CALLSIGN

# Display some debug information

echo
echo

ip addr show ax0
