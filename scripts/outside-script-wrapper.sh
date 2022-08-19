#!/bin/bash
set -euo pipefail

if [[ ! -e "/htp1-root/dev/null" ]]; then
  mknod -m 666 /htp1-root/dev/null c 1 3
fi

if [[ ! -e "/htp1-root/dev/zero" ]]; then
  mknod -m 666 /htp1-root/dev/zero c 1 5
fi
touch /fs_mod_marker
/bin/bash "$@"
OUTPUT=$( find / -mount -type f -newer /fs_mod_marker )
if [[ ! -f "/modified_fs_ok" && ${OUTPUT} ]]; then
  echo Found leftover files in the container when executing "$@" !
  echo This means either your accidentally modified e.g. /etc
  echo instead of /htp1-root/etc, or that you forogt to clean up
  echo some scratch files.
  echo $OUTPUT
  exit 1
fi
