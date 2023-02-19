#!/bin/bash
set -euo pipefail

mkdir -p /installer-root/root/.ssh
cp -f /htp1-mods/scripts/assets/installer-root-ssh-authorized_keys /installer-root/root/.ssh/authorized_keys
chmod -R 700 /installer-root/root/.ssh
