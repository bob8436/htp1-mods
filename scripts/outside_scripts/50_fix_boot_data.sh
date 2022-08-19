#!/bin/bash
set -euo pipefail

cp -f /htp1-mods/scripts/assets/etc-fstab /htp1-root/etc/fstab
cp -f /htp1-mods/scripts/assets/boot-armbianEnv.txt /htp1-root/boot/armbianEnv.txt
