#!/bin/bash
set -euo pipefail

mkdir -p /installer-root/vfat
rm -rf /installer-root/vfat/*
cp -r /htp1-root/vfat/* /installer-root/vfat/
