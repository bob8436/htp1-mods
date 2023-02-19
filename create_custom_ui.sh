#!/bin/bash
set -euo pipefail

source env.sh

if [[ -f localenv.sh ]]; then
  source localenv.sh
fi

if [[ -z "${WORK_DIR}" ]]; then
  echo "WORK_DIR undefined; environment not properly set up"
  return -1
fi

VERSION="0.17.0"

rm -rf ${SCRATCH_DIR}/custom_ui ${SCRATCH_DIR}/custom_ui.tar.gz
mkdir -p ${WORK_DIR} ${SCRATCH_DIR} ${SCRATCH_DIR}/custom_ui ${OUTPUT_DIR}


wget -O ${SCRATCH_DIR}/custom_ui.tar.gz https://github.com/jsoosiah/htp1-custom-controller/archive/refs/tags/${VERSION}.tar.gz

tar xzf ${SCRATCH_DIR}/custom_ui.tar.gz -C ${SCRATCH_DIR}/custom_ui

sed -i "s#createWebHistory()#createWebHistory('/custom/')#g" ~/htp1-work-dir/scratch/custom_ui/htp1-custom-controller-${VERSION}/src/router.js

MYUID=$(id -u)

docker run --rm -v ${SCRATCH_DIR}/custom_ui:/custom_ui -it node:18.14.0-bullseye \
    bash -c "cd /custom_ui/htp1-custom-controller-${VERSION}/ && npm install && VUE_APP_PUBLIC_PATH=/custom/ npm run build ; chown -R ${MYUID} /custom_ui"


mv ${SCRATCH_DIR}/custom_ui/htp1-custom-controller-${VERSION}/dist ${SCRATCH_DIR}/custom_ui/htp1-custom-controller-${VERSION}/custom

tar czf ${MODS_BASE_DIR}/scripts/assets/custom.tar.gz -C ${SCRATCH_DIR}/custom_ui/htp1-custom-controller-${VERSION} custom
