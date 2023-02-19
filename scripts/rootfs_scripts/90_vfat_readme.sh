#!/bin/bash
set -euo pipefail

cp -f /htp1-mods/scripts/assets/vfat-README.txt /vfat/README.txt
echo $'\n\n\n' >> /vfat/README.txt
cat /htp1-mods/CHANGELOG.md >> /vfat/README.txt

cp -f /htp1-mods/scripts/assets/vfat-LICENSE.txt /vfat/LICENSE.txt
