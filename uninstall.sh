#!/bin/bash

# Uninstall dependendencies
echo "Removing dependendencies"
apt-get remove -y dhcp-helper parprouted isc-dhcp-client

echo "Deleting /data/plugins/system_controller"
sudo rm -rf /data/plugins/system_controller/wired_to_wireless_bridge/

echo "Performing teardown"
source ./scripts/bridge_setup.sh stop

echo "Done"
echo "pluginuninstallend"
