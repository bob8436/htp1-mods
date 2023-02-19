#!/bin/bash
set -euo pipefail

source env.sh

if [[ -f localenv.sh ]]; then
  source localenv.sh
fi

# The HTP-1 rescue disk is an SD-card image containing a bootable Linux distribution
# which boots up and reinstalls the root filesystem of the HTP-1 while also updating
# other internal components' firmware. The image of the HTP-1 root filesystem resides
# at /opt/install/rootfs.xz and the install script is /opt/install/restore.sh. This
# script produces two outputs: output-sd.img.xz, which is a bootable version of the
# HTP-1 root filesystem suitable for running directly from an SD-card. Second, we
# produce output-installer.img.xz, which is a recovery image that installs this HTP-1
# firmware distribution into the HTP-1's internal eMMC. The flow of this framework
# is as follows:
#
# 1. Mount the image of the recovery installer at ${RESCUE_IMAGE_PATH}
# 2. Extract the rootfs and mount it as ${HTP1_ROOT_DIR}
# 3. Run our rootfs scripts against ${HTP1_ROOT_DIR} to customize it
# 4. Export ${HTP1_ROOT_DIR} to a bootable SD-card image (output-sd.img.xz)
# 5. modify ${HTP1_ROOT_DIR} for installation and replace ${RESCUE_IMAGE_PATH}/opt/install/rootfs.xz
# 6. Export the installer at ${RESCUE_IMAGE_PATH} as output-installer.img.xz

if [[ -z "${WORK_DIR}" ]]; then
  echo "WORK_DIR undefined; environment not properly set up"
  return -1
fi

mkdir -p ${WORK_DIR}
mkdir -p ${HTP1_ROOT_DIR}

rm -rf ${WORK_DIR}/output ${WORK_DIR}/scratch
mkdir -p ${WORK_DIR}/output ${WORK_DIR}/scratch

if [[ ! -f ${WORK_DIR}/rescue.zip ]]; then
  echo Fetching ${HTP1_RESCUE_URL}
  wget --show-progress -O ${WORK_DIR}/rescue.zip ${HTP1_RESCUE_URL}
fi

rm -rf ${WORK_DIR}/rescue_zip_extracted
echo Extracting rescue.zip...
unzip ${WORK_DIR}/rescue.zip -d ${WORK_DIR}/rescue_zip_extracted
echo Extracting rescue image xz
xzcat -T 0 ${WORK_DIR}/rescue_zip_extracted/htp1_rescue_v1.8g.img.xz > ${SCRATCH_DIR}/rescue_disk.img

echo Creating docker image in which to run scripts...
docker build -t htp1-container ${MODS_BASE_DIR}/docker

echo Building JSoosiah custom image...
${MODS_BASE_DIR}/create_custom_ui.sh

RESCUE_IMAGE_PATH=${SCRATCH_DIR}/rescue_disk.img

RESCUE_IMAGE_DEVICE=$( sudo losetup --show -f -P ${RESCUE_IMAGE_PATH} )
echo Rescue image device is $RESCUE_IMAGE_DEVICE

sudo mkdir -p ${RESCUE_IMAGE_ROOT_DIR}
sudo mount ${RESCUE_IMAGE_DEVICE}p1 ${RESCUE_IMAGE_ROOT_DIR}
sudo mkdir -p ${RESCUE_IMAGE_ROOT_DIR}/vfat
sudo mount ${RESCUE_IMAGE_DEVICE}p2 ${RESCUE_IMAGE_ROOT_DIR}/vfat

echo Extracting rootfs
xzcat -T0 ${RESCUE_IMAGE_ROOT_DIR}/opt/install/rootfs.xz > ${SCRATCH_DIR}/htp_rootfs.img


echo Mounting RootFS
ROOTFS_DEVICE=$( sudo losetup --show -f -P ${SCRATCH_DIR}/htp_rootfs.img )
mkdir -p ${HTP1_ROOT_DIR}
sudo mount ${ROOTFS_DEVICE} ${HTP1_ROOT_DIR}

${MODS_BASE_DIR}/run-rootfs-scripts.sh

${MODS_BASE_DIR}/finalize-sd-image.sh

${MODS_BASE_DIR}/run-installer-scripts.sh

${MODS_BASE_DIR}/modify-installer-image.sh

echo Unmounting rescue image
sudo umount ${RESCUE_IMAGE_ROOT_DIR}/vfat ${RESCUE_IMAGE_ROOT_DIR}
sudo losetup -d ${RESCUE_IMAGE_DEVICE}

sudo bash -c "xz -T0 -c -z ${RESCUE_IMAGE_PATH} > ${OUTPUT_DIR}/installer-output.img.xz"

sudo umount ${ROOTFS_DEVICE}
sudo losetup -d ${ROOTFS_DEVICE}

