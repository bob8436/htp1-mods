#!/bin/bash
set -euo pipefail

/usr/bin/htp1-custom-ui-background-service-linuxstatic-armv7 --ip-address `ip route get 1 | awk '{print $NF;exit}'`

