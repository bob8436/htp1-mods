#!/bin/bash
set -euo pipefail

cp -f /htp1-mods/scripts/assets/installer-boot.bmp /installer-root/boot/boot.bmp
convert /htp1-mods/scripts/assets/installer-boot.bmp -write bgra:- null: | gzip -c > /installer-root/opt/install/FactoryRestore18g-red.fb0.gz
convert /htp1-mods/scripts/assets/installer-bob8436-info.bmp -write bgra:- null: | gzip -c > /installer-root/opt/install/Info.fb0.gz
