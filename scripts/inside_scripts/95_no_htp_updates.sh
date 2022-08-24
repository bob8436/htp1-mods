#!/bin/bash
set -euo pipefail

rm -rf /opt/olympia/.git
cp -f /htp1-mods/scripts/assets/opt-olympia-gitignore /opt/olympia/.gitignore
mkdir -p /fakegit
git init --bare /fakegit/htp1.git
git config --global user.name "bob8436"
git config --global user.email "nobody@nobody.com"
cd /opt/olympia
git init
git remote add htp1 /fakegit/htp1.git
git add .gitignore

VERSION=$( cat /htp1-mods/VERSION )
echo "ffffffff: V"${VERSION}" Modifications to the stock HTP1 firmware" >> /fakegit/commit.txt
echo $'\n' >> /fakegit/commit.txt
cat /htp1-mods/CHANGELOG.md >> /fakegit/commit.txt
git commit -F /fakegit/commit.txt
git push -u htp1 master

cp -f /htp1-mods/scripts/assets/noop.sh /opt/olympia/update_helper.sh
chmod +x /opt/olympia/update_helper.sh

cp -f /htp1-mods/scripts/assets/noop.sh /opt/olympia/update_main.sh
chmod +x /opt/olympia/update_main.sh

cp -f /htp1-mods/scripts/assets/noop.sh /opt/olympia/update_on_boot.sh
chmod +x /opt/olympia/update_on_boot.sh

cp -f /htp1-mods/scripts/assets/noop.sh /opt/olympia/update_on_restarted.sh
chmod +x /opt/olympia/update_on_restarted.sh

cp -f /htp1-mods/scripts/assets/noop.sh /opt/olympia/update_on_restarted2.sh
chmod +x /opt/olympia/update_on_restarted2.sh


rm -rf /opt/olympia/config/laird-backport
rm -rf /opt/olympia/apm/*.rom
rm -rf /opt/olympia/sys/*.deb
