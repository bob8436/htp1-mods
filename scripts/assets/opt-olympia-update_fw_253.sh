#!/bin/bash

cd $(dirname $0)
echo update_fw_253.sh ::time:: $(date -R) 2>&1 | tee -a /var/log/olympia/update.log

. msg2nodered.sh

msg2nodered 0 12 8 "Firmware Update Started" "main:7"

touch /var/lib/olympia/flashing_apm_dont_start
/opt/olympia/mq send /mq__console "n" 2>&1 | tee -a /var/log/olympia/update.log
sleep 1
/opt/olympia/mq send /mq__console "q" 2>&1 | tee -a /var/log/olympia/update.log
sleep 1
killall avController 2>&1 | tee -a /var/log/olympia/update.log
/opt/olympia/int3p/stroke430 0 2>&1 | tee -a /var/log/olympia/update.log

# turn off USB shield
/opt/olympia/setup_shield.sh off

cd /opt/olympia/apm
./updateAPM.sh APM-119_v253_signed.rom 2>&1 | tee -a /var/log/olympia/update.log
printf "changemso [{\"op\":\"replace\",\"path\":\"/versions/apm100\", \"value\":\"Just updated, please do a full refresh\"}]" "$1" "$4" | nc -w 1 localhost 1799 2>&1 | tee -a /var/log/olympia/update.log
log2ram write
sync
sleep 5
reboot
