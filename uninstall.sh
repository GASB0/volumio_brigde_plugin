#!/bin/bash

# Uninstall dependendencies
# apt-get remove -y


echo "Deleting /data/plugins/system_controller"
sudo rm -rf /data/plugins/system_controller/wired_to_wireless_bridge/

echo "Performing teardown"
source ./scripts/bridge_teardown.sh

echo "Done"
echo "pluginuninstallend"
