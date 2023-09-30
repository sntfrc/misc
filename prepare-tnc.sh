#!/bin/bash

if (( $EUID != 0 )); then
	echo "This script needs root access to work."
	exit 1
fi

echo
echo "=== TCP/IP over AX.25 on software TNC setup script ==="
echo "(C) 2023 Federico Santandrea, IU4AAJ"
echo
echo "This will prepare a newly installed Debian system to act as a TCP/IP packet radio endpoint."
echo "It will also act as an open router for the declared subnet for any other connected machine."
echo
echo "Warning: any already present Direwolf or axports configuration will be overwritten."
echo
echo "Press any key to continue."
read

echo
echo -n "Your callsign and SSID (ex.: N0CALL-5)? "; read CALL
echo -n "Your radio IP address and subnet (ex.: 192.168.73.100/24)? "; read IPADDR

apt install -y --no-install-recommends pulseaudio
apt install -y alsa-utils direwolf ax25-tools ax25-apps

cat << EOF > /etc/systemd/system/tnc.service
[Unit]
After=network.target
Requires=network.target

[Service]
Environment="IPADDR=${IPADDR}"
ExecStart=/usr/local/bin/start-tnc

[Install]
WantedBy=multi-user.target

EOF

cat << EOF > /etc/direwolf.conf
ADEVICE plughw:0,0
PTT CM108

EOF

cat << EOF > /etc/ax25/axports
1	${CALL}	9600	255	2	Packet radio
EOF

cat << EOF > /usr/local/bin/start-tnc
#!/bin/sh

sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.tcp_congestion_control=westwood

direwolf -c /etc/direwolf.conf -p &
until [ -e /dev/pts/0 ]; do sleep 1; done
sleep 2

kissattach /dev/pts/0 1 &
until [ -e /sys/class/net/ax0 ]; do sleep 1; done
sleep 2

kissparms -c 1 -p 1
ip addr add dev ax0 ${IPADDR}

iptables -t nat -A POSTROUTING -o ax0 -j MASQUERADE
iptables -P FORWARD ACCEPT

sleep infinity

EOF

chmod u+x /usr/local/bin/start-tnc
systemctl daemon-reload

echo "Done! Next steps:"
echo " 1. Please edit /etc/direwolf.conf file correctly for your radio."
echo " 2. Run 'sudo alsamixer' and set correct playback and capture volume levels."
echo " 3. Enable TNC service with 'systemctl enable tnc'"
echo
echo "Enjoy packet radio!"
echo "73 de IU4AAJ"
echo

