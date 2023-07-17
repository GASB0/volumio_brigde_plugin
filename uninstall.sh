#!/bin/bash

systemctl stop parprouted.service
systemctl disable parprouted.service

sudo rm /etc/systemd/network/08-wlan0.network
sudo rm /etc/default/dhcp-helper
sudo rm /etc/avahi/avahi-daemon.conf
sudo rm /usr/bin/get-adapter-ip
sudo rm /bin/parprouted_check_changes.sh

sudo rm /etc/systemd/system/parprouted.service

sudo apt remove parprouted dhcp-helper

sudo sed -i "/.*denyinterfaces usb0.*/d" /etc/dhcpcd.conf
echo "The line \"denyinterfaces usb0\" in the /etc/dhcpcd.conf has been removed"
echo "this enable the action of dhcpcd in the usb0 interface"

echo "Done"
echo "pluginuninstallend"
