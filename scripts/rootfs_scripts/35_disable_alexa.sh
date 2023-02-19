#!/bin/bash
set -euo pipefail

#The Alexa integration doesn't work and simply spews logs

cp -f /htp1-mods/scripts/assets/noop.sh /opt/olympia/start-alexa.sh
chmod 755 /opt/olympia/start-alexa.sh
