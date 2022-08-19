#!/bin/bash
set -euo pipefail

SCRIPT_PATH="$1"

echo ==== Running script: ${SCRIPT_PATH}
if [[ "${SCRIPT_PATH}" == *"/inside_scripts/"* ]]; then
  PATH_INSIDE_CHROOT=$( echo $SCRIPT_PATH | sed "s#${MODS_BASE_DIR}#/htp1-mods#g" )
  docker run --rm --platform linux/aarch64 -v ${HTP1_ROOT_DIR}:/htp1-root -v ${MODS_BASE_DIR}:/htp1-root/htp1-mods -it arm64v8/ubuntu /htp1-root/htp1-mods/scripts/inside-script-wrapper.sh ${PATH_INSIDE_CHROOT}
else
  PATH_INSIDE_CONTAINER=$( echo $SCRIPT_PATH | sed "s#${MODS_BASE_DIR}#/htp1-mods#g" )
  docker run --rm --platform linux/aarch64 -v ${HTP1_ROOT_DIR}:/htp1-root -v ${MODS_BASE_DIR}:/htp1-mods -it arm64v8/ubuntu /htp1-mods/scripts/outside-script-wrapper.sh ${PATH_INSIDE_CONTAINER}
fi
