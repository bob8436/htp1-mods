#!/bin/bash

set -euo pipefail

# The global.json saved by node red is comprised almost entirely of the MSO config json
# with only a little more. This script wraps the MSO config json that is exported from
# the HTP-1 web interface with a minimal JSON to import into node-red as the global state

if [[ -f /vfat/config.json && ! -f /opt/olympia/node-red/context/global/global.json ]]; then
  mkdir -p /opt/olympia/node-red/context/global
  echo "{" > /opt/olympia/node-red/context/global/global.json
  echo '"lastIRvol": 0,' >> /opt/olympia/node-red/context/global/global.json
  echo '"newverb": "2023-01-03T22:42:19.763Z",' >> /opt/olympia/node-red/context/global/global.json
  echo -n '"mso": ' >> /opt/olympia/node-red/context/global/global.json
  cat /vfat/config.json >> /opt/olympia/node-red/context/global/global.json
  echo >> /opt/olympia/node-red/context/global/global.json
  echo "}" >> /opt/olympia/node-red/context/global/global.json
fi
