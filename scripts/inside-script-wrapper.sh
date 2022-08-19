#!/bin/bash
set -euo pipefail

#enable name resolution within container
mkdir /htp1-root/run/resolvconf
cp /etc/resolv.conf /htp1-root/run/resolvconf/

chroot /htp1-root /bin/bash "$@"

rm -rf /htp1-root/run/resolvconf/
