#!/bin/bash
set -euo pipefail

mkdir -p /var/log/journal

# The "auto" setting in journal.conf will use that directory when it exists
