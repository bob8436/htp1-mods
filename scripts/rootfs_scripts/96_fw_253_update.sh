#!/bin/bash

wget -O /opt/olympia/apm/APM-119_v253_signed.rom http://htp1.beingbuilt.net/APM-119_v253_signed.rom
cp -f /htp1-mods/scripts/assets/opt-olympia-update_fw_253.sh /opt/olympia/update_fw_253.sh
chmod +x /opt/olympia/update_fw_253.sh
