#!/bin/bash
set -euo pipefail

cp -f /htp1-mods/scripts/assets/opt-olympia-boot.bmp /opt/olympia/boot.bmp

apt-get install -y imagemagick
convert /htp1-mods/scripts/assets/opt-olympia-boot.bmp -write bgra:- null: | gzip -c > /opt/olympia/boot.fb0.gz
