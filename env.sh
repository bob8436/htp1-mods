#!/bin/bash
export WORK_DIR=${HOME}/htp1-work-dir
export OUTPUT_DIR=${WORK_DIR}/output
export SCRATCH_DIR=${WORK_DIR}/scratch
export HTP1_RESCUE_URL=https://www.mashie.org/htp1/rescue_v1.8.zip
export HTP1_ROOT_DIR=${SCRATCH_DIR}/htp1-root
export RESCUE_IMAGE_ROOT_DIR=${SCRATCH_DIR}/rescue-image-root
export MODS_BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

