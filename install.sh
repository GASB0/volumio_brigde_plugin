#!/bin/bash
set -e

[ $EUID -ne 0 ] && echo "run as root" >&2 && exit 1

echo "Configuring dhcpcd"
if [[ $(grep -oE ".*denyinterfaces usb0.*" /etc/dhcpcd.conf) = "" ]];
then
    echo "denyinterfaces usb0" >> /etc/dhcpcd.conf
    sudo systemctl restart dhcpcd
else
    echo "The usb0 interface already has dhcpcd disabled"
fi


echo "Installing wired to wireless bridge Dependencies"
# Install the required packages via apt-get
sudo apt update && apt install -y parprouted dhcp-helper

systemctl stop dhcp-helper
systemctl enable dhcp-helper

# Prevent the networking and dhcpcd service from running. networking.service
# is a debian-specific package and not the same as systemd-network. Disable the
# dhcpcd service as well.
systemctl mask networking.service dhcpcd.service
systemctl enable systemd-networkd.service systemd-resolved.service

# Use systemd-resolved to handle the /etc/resolf.conf config
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

cat > /etc/systemd/network/08-wlan0.network <<EOF
[Match]
Name=wlan0
[Network]
DHCP=yes
IPForward=yes
EOF

cat > /etc/default/dhcp-helper <<EOF
DHCPHELPER_OPTS="-b wlan0"
EOF

cat <<'EOF' >/etc/avahi/avahi-daemon.conf
[server]
use-ipv4=yes
use-ipv6=yes
ratelimit-interval-usec=1000000
ratelimit-burst=1000
[wide-area]
enable-wide-area=yes
[publish]
publish-hinfo=no
publish-workstation=no
[reflector]
enable-reflector=yes
[rlimits]
EOF

echo "Create a helper script to get an adapter's IP address"
cat <<'EOF' >/usr/bin/get-adapter-ip
#!/usr/bin/env bash
/sbin/ip -4 -br addr show ${1} | /bin/grep -Po "\\d+\\.\\d+\\.\\d+\\.\\d+"
EOF
chmod +x /usr/bin/get-adapter-ip

echo "Creating the actual parprouted service"
cat <<'EOF' >/etc/systemd/system/parprouted.service
[Unit]
Description=proxy arp routing service
Documentation=https://raspberrypi.stackexchange.com/q/88954/79866
[Service]
Type=forking
# Restart until wlan0 gained carrier
Restart=on-failure
RestartSec=5
TimeoutStartSec=30
ExecStartPre=/lib/systemd/systemd-networkd-wait-online --interface=wlan0 --timeout=6 --quiet
ExecStartPre=/bin/echo 'systemd-networkd-wait-online: wlan0 is online'
# clone the dhcp-allocated IP to usb0 so dhcp-helper will relay for the correct subnet
ExecStartPre=/bin/bash -c '/sbin/ip addr add $(/usr/bin/get-adapter-ip wlan0)/32 dev usb0'
ExecStartPre=/sbin/ip link set dev usb0 up
ExecStartPre=/sbin/ip link set wlan0 promisc on
ExecStart=-/usr/sbin/parprouted usb0 wlan0
ExecStopPost=/sbin/ip link set wlan0 promisc off
ExecStopPost=/sbin/ip link set dev usb0 down
ExecStopPost=/bin/bash -c '/sbin/ip addr del $(/usr/bin/get-adapter-ip usb0)/32 dev usb0'
[Install]
WantedBy=wpa_supplicant@wlan0.service
EOF


# parprouted Inizialization
systemctl daemon-reload
systemctl enable parprouted.service

systemctl enable wpa_supplicant@wlan0 dhcp-helper systemd-networkd systemd-resolved
systemctl start wpa_supplicant@wlan0 dhcp-helper systemd-networkd systemd-resolved

echo "In order for the plugin to start working properly, please reboot your system"

#requred to end the plugin install
echo "plugininstallend"
