#!/usr/bin/env bash

wiredInterface='usb0'

start(){
  echo 'volumio' | sudo -S bash -c "
	echo Enabling ip forwarding and proxy_arp
	echo 1 > /proc/sys/net/ipv4/ip_forward
	echo 1 > /proc/sys/net/ipv4/conf/all/proxy_arp

	echo Setting up the appropriate interfaces
	ip link set dev wlan0 promisc on
	ip link set dev wlan0 up
	ip link set dev $wiredInterface promisc on
	ip link set dev $wiredInterface up

	ip addr add $(ip addr show wlan0 | perl -wne 'm|^\s+inet (.*)/| && print $1')/32 dev $wiredInterface

	echo Setting up parprouted and dhcp-helper
	parprouted $wiredInterface wlan0
	dhcp-helper -b wlan0
  "
}

stop(){
  echo 'volumio' | sudo -S bash -c "
    echo Stopping bridge
    sudo ip addr flush dev $wiredInterface
    kill -9 $(pidof dhcp-helper)
    kill -9 $(pidof parprouted)
    echo Disabling ip forwarding and proxy_arp
    echo 0 > /proc/sys/net/ipv4/ip_forward
    echo 0 > /proc/sys/net/ipv4/conf/all/proxy_arp
  "
}

case $1 in
	'start')
		start;
		;;
	'stop')
		stop;
		;;
	'restart')
		stop;
		start;
		;;
	*)
	echo $"Usage: $0 {start|stop|restart}"
	exit 1
esac
