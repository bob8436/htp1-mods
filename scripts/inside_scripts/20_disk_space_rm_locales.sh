#!/bin/bash
set -euo pipefail

find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en' ! -name 'de*' !  -name 'es*' ! -name 'ja*' ! -name 'fr*' ! -name 'zh*' |xargs rm -rf
