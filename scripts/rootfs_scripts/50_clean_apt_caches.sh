#!/bin/bash
set -euo pipefail

echo Cleaning apt cache
apt-get clean
rm -rf /var/lib/apt/lists/*
