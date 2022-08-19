#!/bin/bash
set -euo pipefail

echo Moving SSH to conditional start based on /vfat/authorized_keys
rm -f /root/.ssh/authorized_keys
cp -f /htp1-mods/scripts/assets/lib-systemd-system-ssh.service /lib/systemd/system/ssh.service

cp -f /htp1-mods/scripts/assets/root-copy-ssh-key.sh /root/copy-ssh-key.sh
chmod 755 /root/copy-ssh-key.sh

cp -f /htp1-mods/scripts/assets/etc-systemd-system-authkey.service /etc/systemd/system/authkey.service
systemctl enable authkey.service
