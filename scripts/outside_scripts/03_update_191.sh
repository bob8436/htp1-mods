#!/bin/bash
set -euo pipefail
cd /htp1-root/opt/olympia

apt-get update
apt-get install -y git
# apt-get install will have added a bunch to FS and that's OK
touch /fs_mod_marker

git pull

