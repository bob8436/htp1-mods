#!/bin/bash
set -euo pipefail

tar xzf /htp1-mods/scripts/assets/custom.tar.gz -C /opt/olympia/node-red/static

wget -O /usr/bin/htp1-custom-ui-background-service-linuxstatic-armv7 https://github.com/jsoosiah/htp1-custom-ui-background-service-console/releases/download/1.0.2/htp1-custom-ui-background-service-linuxstatic-armv7
chmod +x /usr/bin/htp1-custom-ui-background-service-linuxstatic-armv7

cp -f /htp1-mods/scripts/assets/etc-systemd-system-background-service.service /etc/systemd/system/background-service.service
systemctl enable background-service.service

cp -f /htp1-mods/scripts/assets/usr-bin-background-service.sh /usr/bin/background-service.sh
chmod +x /usr/bin/background-service.sh
