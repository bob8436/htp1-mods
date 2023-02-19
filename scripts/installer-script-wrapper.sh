#!/bin/bash
set -euo pipefail

if [[ ! -e "/htp1-root/dev/null" ]]; then
  mknod -m 666 /htp1-root/dev/null c 1 3
fi

if [[ ! -e "/htp1-root/dev/zero" ]]; then
  mknod -m 666 /htp1-root/dev/zero c 1 5
fi

#enable name resolution within container
mkdir -p /htp1-root/run/resolvconf
cp /etc/resolv.conf /htp1-root/run/resolvconf/

/bin/bash "$@"

rm -rf /htp1-root/run/resolvconf/
