#!/bin/bash
set -euo pipefail

SCRIPT_PATH="$1"

echo ==== Running script: ${SCRIPT_PATH}
PATH_INSIDE_CONTAINER=$( echo $SCRIPT_PATH | sed "s#${MODS_BASE_DIR}#/htp1-mods#g" )
if [[ "${SCRIPT_PATH}" == *"/rootfs_scripts/"* ]]; then
  docker run --rm --platform linux/arm/v7 -v ${HTP1_ROOT_DIR}:/htp1-root -v ${MODS_BASE_DIR}:/htp1-root/htp1-mods -it htp1-container /htp1-root/htp1-mods/scripts/rootfs-script-wrapper.sh ${PATH_INSIDE_CONTAINER}
elif [[ "${SCRIPT_PATH}" == *"/installer_scripts/"* ]]; then
  docker run --rm --platform linux/arm/v7 -v ${HTP1_ROOT_DIR}:/htp1-root -v ${RESCUE_IMAGE_ROOT_DIR}:/installer-root -v ${MODS_BASE_DIR}:/htp1-mods -it htp1-container /htp1-mods/scripts/installer-script-wrapper.sh ${PATH_INSIDE_CONTAINER}
else
  exit 1
fi
