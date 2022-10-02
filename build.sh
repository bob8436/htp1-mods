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

mkdir -p ${WORK_DIR}
mkdir -p ${HTP1_ROOT_DIR}

rm -rf ${WORK_DIR}/output_root_fs
rm -rf ${WORK_DIR}/output.img

if [[ ! -f ${WORK_DIR}/rescue.zip ]]; then
  echo Fetching ${HTP1_RESCUE_URL}
  wget --show-progress -O ${WORK_DIR}/rescue.zip ${HTP1_RESCUE_URL}
fi

rm -rf ${WORK_DIR}/rescue_zip_extracted
echo Extracting rescue.zip...
unzip ${WORK_DIR}/rescue.zip -d ${WORK_DIR}/rescue_zip_extracted
echo Extracting rescue image xz
xz -T 0 -d ${WORK_DIR}/rescue_zip_extracted/htp1_rescue_v1.8g.img.xz
RESCUE_IMAGE_DEVICE=$( sudo losetup --show -f -P ${WORK_DIR}/rescue_zip_extracted/htp1_rescue_v1.8g.img )
echo Rescue image device is $RESCUE_IMAGE_DEVICE

RESCUE_IMAGE_DIR=${WORK_DIR}/rescue-image
sudo mkdir -p ${RESCUE_IMAGE_DIR}
sudo mount ${RESCUE_IMAGE_DEVICE}p1 ${RESCUE_IMAGE_DIR}
echo Extracting rootfs
xzcat -T0 ${RESCUE_IMAGE_DIR}/opt/install/rootfs.xz > ${WORK_DIR}/htp_rootfs.img
echo Unmounting rescue image
sudo umount ${RESCUE_IMAGE_DIR}
sudo losetup -d ${RESCUE_IMAGE_DEVICE}

echo Mounting RootFS
ROOTFS_DEVICE=$( sudo losetup --show -f -P ${WORK_DIR}/htp_rootfs.img )
sudo mount ${ROOTFS_DEVICE} ${HTP1_ROOT_DIR}

${MODS_BASE_DIR}/run-scripts.sh

${MODS_BASE_DIR}/finalize-image.sh

sudo umount ${ROOTFS_DEVICE}

sudo losetup -d ${ROOTFS_DEVICE}
