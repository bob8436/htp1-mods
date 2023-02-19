#!/bin/bash
set -euo pipefail
apt remove -y unattended-upgrades
cp -f /htp1-mods/scripts/assets/etc-apt-apt.conf.d-02periodic /etc/apt/apt.conf.d/02periodic
cp -f /htp1-mods/scripts/assets/etc-apt-apt.conf.d-20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades
