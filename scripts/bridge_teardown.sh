#!/usr/bin/env bash

# Stablishing the interfaces
wiredInterface='eth0';
wirelessInterface='wlan0';

echo "volumio" | sudo -S bash -c '
echo 0 > /proc/sys/net/ipv4/ip_forward;
echo 0 > /proc/sys/net/ipv4/conf/all/proxy_arp;
'

echo "volumio" | sudo -S -i << EOF
	echo "The bridge has been tore down" > /home/volumio/newTest.txt;

	# Cleaning NAT tables 
	iptables -t nat -F;

	# Configuring the network interfaces
	ip link set dev $wiredInterface down;
	ip addr flush dev $wiredInterface;
	ip link set dev $wiredInterface up;

	ip link set dev $wirelessInterface up;
EOF
