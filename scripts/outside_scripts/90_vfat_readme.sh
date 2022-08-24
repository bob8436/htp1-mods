#!/bin/bash
set -euo pipefail

cp -f /htp1-mods/scripts/assets/vfat-README.txt /htp1-root/vfat/README.txt
echo $'\n\n\n' >> /htp1-root/vfat/README.txt
cat /htp1-mods/CHANGELOG.md >> /htp1-root/vfat/README.txt

cp -f /htp1-mods/scripts/assets/vfat-LICENSE.txt /htp1-root/vfat/LICENSE.txt
