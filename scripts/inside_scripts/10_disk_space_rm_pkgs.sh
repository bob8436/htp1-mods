#!/bin/bash
set -euo pipefail

apt-get remove -y linux-headers-next
apt-get remove -y linux-headers-next-sunxi
apt-get remove -y linux-image-next-sunxi
