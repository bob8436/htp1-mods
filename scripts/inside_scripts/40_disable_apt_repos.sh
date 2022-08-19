#!/bin/bash
set -euo pipefail

echo Disabling all apt repositories
FILES=/etc/apt/sources.list.d/*.list

echo deleting contents of /etc/apt/sources.list
truncate -s 0 /etc/apt/sources.list
for FILE in ${FILES}
do
  echo deleting contents of ${FILE}
  sudo truncate -s 0 ${FILE}
done
