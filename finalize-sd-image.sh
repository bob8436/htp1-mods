#!/bin/bash
set -euo pipefail

xzcat -T0 ${MODS_BASE_DIR}/empty3pfs.img.xz > ${SCRATCH_DIR}/output-sd.img
OUTPUTDEV=$( sudo losetup --show -f -P ${SCRATCH_DIR}/output-sd.img )

mkdir -p ${SCRATCH_DIR}/sd_root_fs
sudo mount ${OUTPUTDEV}p1 ${SCRATCH_DIR}/sd_root_fs

sudo mkdir -p ${SCRATCH_DIR}/sd_root_fs/var/log
sudo mount ${OUTPUTDEV}p2 ${SCRATCH_DIR}/sd_root_fs/var/log

sudo mkdir -p ${SCRATCH_DIR}/sd_root_fs/vfat
sudo mount ${OUTPUTDEV}p3 ${SCRATCH_DIR}/sd_root_fs/vfat

docker run --rm --platform linux/aarch64 -v ${HTP1_ROOT_DIR}:/htp1-root -v ${SCRATCH_DIR}/sd_root_fs:/output-root -it arm64v8/ubuntu bash -c "tar -cp -C /htp1-root . | tar -xp -C /output-root"

sudo umount ${OUTPUTDEV}p3
sudo umount ${OUTPUTDEV}p2
sudo umount ${OUTPUTDEV}p1
sudo losetup -d ${OUTPUTDEV}
xzcat -T 0 -z ${SCRATCH_DIR}/output-sd.img > ${OUTPUT_DIR}/output-sd.img.xz
