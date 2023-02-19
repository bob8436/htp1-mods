#!/bin/bash
set -euo pipefail

# Get a listing of the path to each script we need to run, sorted by
# filename only. This way we get the correct ordering
SCRIPTS=$( find ${MODS_BASE_DIR}/scripts/installer_scripts/  \
    -maxdepth 1 -regex ".*/[0-9][0-9]_[^/]*" -printf '%f\t%p\n' | sort -k1 | \
    cut -d$'\t' -f2 )
for SCRIPT in ${SCRIPTS}
do
  ${MODS_BASE_DIR}/scripts/run-script.sh ${SCRIPT}
done
