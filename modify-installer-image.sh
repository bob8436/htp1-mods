#!/bin/bash
set -euo pipefail

echo rescue image root dir is ${RESCUE_IMAGE_ROOT_DIR}

xzcat -T0 ${MODS_BASE_DIR}/emptyrootfs.img.xz > ${SCRATCH_DIR}/installer-output-rootfs.img
ROOTFSDEV=$( sudo losetup --show -f ${SCRATCH_DIR}/installer-output-rootfs.img )

mkdir -p ${SCRATCH_DIR}/installer_root_fs
sudo mount ${ROOTFSDEV} ${SCRATCH_DIR}/installer_root_fs

docker run --rm --platform linux/aarch64 -v ${HTP1_ROOT_DIR}:/htp1-root -v ${SCRATCH_DIR}/installer_root_fs:/output-root -it arm64v8/ubuntu bash -c "tar -cp -C /htp1-root . | tar -xp -C /output-root"

sudo umount ${ROOTFSDEV}
sudo losetup -d ${ROOTFSDEV}

sudo bash -c "xz -T0 -z -c ${SCRATCH_DIR}/installer-output-rootfs.img > ${RESCUE_IMAGE_ROOT_DIR}/opt/install/rootfs.xz"
