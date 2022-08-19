#!/bin/bash
rm -f /root/.ssh/authorized_keys
cp -f /vfat/authorized_keys /root/.ssh/authorized_keys
chmod 700 /root/.ssh/authorized_keys
exit 0
