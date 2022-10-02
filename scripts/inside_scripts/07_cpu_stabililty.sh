#!/bin/bash
set -euo pipefail

cd /opt/olympia/config
cp -f /htp1-mods/scripts/assets/opt-olympia-config-cpu-volt.dts /opt/olympia/config/cpu-volt.dts
/opt/olympia/config/armbian-add-overlay /opt/olympia/config/cpu-volt.dts
cp -f /htp1-mods/scripts/assets/etc-default-cpufrequtils /etc/default/cpufrequtils
sed -i '/^cpufreq-set/d' /opt/olympia/start-olympia.sh
sed -i '/^echo "Disable CPU speed governor/d' /opt/olympia/start-olympia.sh
