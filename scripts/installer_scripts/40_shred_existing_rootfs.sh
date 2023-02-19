#!/bin/bash
set -euo pipefail

shred -n 0 -z /installer-root/opt/install/rootfs.xz
