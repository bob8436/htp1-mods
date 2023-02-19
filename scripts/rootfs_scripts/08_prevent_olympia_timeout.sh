#!/bin/bash
set -euo pipefail

sed -i '/^LOOP=10/d' /opt/olympia/start-olympia.sh
sed -i 's/sntp -t 60/sntp -t 10/g' /opt/olympia/start-olympia.sh
