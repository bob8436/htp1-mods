#!/bin/bash
set -euo pipefail

# Remove the pre-existing global state if it exists so we can restore any config.json to it on boot
rm -f /opt/olympia/node-red/context/global/global.json

cp -f /htp1-mods/scripts/assets/etc-systemd-system-configjson.service /etc/systemd/system/configjson.service
cp -r /htp1-mods/scripts/assets/opt-olympia-restore-config.sh /opt/olympia/restore-config.sh
chmod 755 /opt/olympia/restore-config.sh
systemctl enable configjson.service
