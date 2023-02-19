# As rescue.sh, this is the HTP-1 factory restore script.
# As reetore.sh, it's a work in progress.
# Version 1.8, designed to copy in a full working system without checking any servers.

echo " "
echo "restore.sh version 1.8g."
echo "Command 'service install stop' to stop the install."
echo " "

ethtool -s eth0 advertise 0x00f
ethtool -s eth0 speed 100

systemctl stop lightdm

zcat /opt/install/FactoryRestore18g-red.fb0.gz > /dev/fb0
echo waiting 10 seconds with splash screen
sleep 10

# An inserted USB memory stick pause rescue flashing
function msg {
    wall "$1"
    echo "$1" > /dev/ttyS0
    echo "$1" | nc -w 0 -u -b 255.255.255.255 12345
}

[[ -f /tmp/stop ]] && rm /tmp/stop
while [[ -b /dev/sda ]]; do
    #ideally a zcat here...
    msg "$(date -Is) Waiting because USB storage found. touch /tmp/stop; progress broadcast UDP 0.0.0.0:12345"
    echo "$(date -Is) Found USB storage. Remove and power cycle" > /tmp/olymsg.txt
    if [[ -f /tmp/stop ]]; then
        wall "Found /tmp/stop, terminating"
        echo "Found /tmp/stop, terminating" > /dev/ttyS0
        exit 1
    fi
    sleep 1
done

# Display warning messages
zcat /opt/install/Info.fb0.gz > /dev/fb0
echo waiting 30 seconds with info
echo " "
echo "restore.sh version 1.8g."
echo "Command 'service install stop' to stop the install."
echo " "

sleep 30

zcat /opt/install/Warning.fb0.gz > /dev/fb0
echo waiting 10 seconds with warning
sleep 10

msg "$(date -Is) Starting u-boot/Linux factory reflash rescue"


export FLASHER_VER='1.8.8'

#export URL_BASE=http://192.168.97.48:1880/
export NODE_CMD=/root/.nvm/versions/node/v9.5.0/bin/node
if [ -b "/dev/mmcblk1boot0" ]; then
    export EMMC_DEV=mmcblk1
elif  [ -b "/dev/mmcblk2boot0" ]; then
    export EMMC_DEV=mmcblk2
else
    echo "Abort script: No eMMC device found."
    exit 1
fi
export EMMC_BASE=/dev/${EMMC_DEV}
export EMMC_RO=${EMMC_BASE}boot0

echo "FLASHEE PID=$$ : install.sh started $(date -R | sed 's/.*\([0-9][0-9]:[0-9][0-9]:[0-9][0-9]\).*/\1/')" > /tmp/olymsg.txt
#wall "FLASHEE PID=$$ : install.sh started $(date -R | sed 's/.*\([0-9][0-9]:[0-9][0-9]:[0-9][0-9]\).*/\1/')"

# Sanity Check
# DO NOT ATTEMPT TO USE THIS SCRIPT WHILE FILESYSTEM IS MOUNTED!
if grep ${EMMC_BASE}p1 /proc/mounts; then
    echo "Abort script: Filesystem ${EMMC_BASE}p1 is mounted. Are you running from eMMC?"
    echo "FLASHEE PID=$$ : ERROR: Filesystem ${EMMC_BASE}p1 is mounted $(date -R | sed 's/.*\([0-9][0-9]:[0-9][0-9]:[0-9][0-9]\).*/\1/')" > /tmp/olymsg.txt
    wall "FLASHEE PID=$$ : ERROR: Filesystem ${EMMC_BASE}p1 is mounted $(date -R | sed 's/.*\([0-9][0-9]:[0-9][0-9]:[0-9][0-9]\).*/\1/')"
    exit 1
fi

echo "Starting install process"
echo '## INFO ## Starting install process. Total time about 8-15 minutes'
# The "Small MAC" is the eth0 MAC address from the eeprom in lower case without any separators
SMALLMAC=$(${NODE_CMD} -e "console.log(require('fs').readFileSync('/sys/bus/i2c/devices/1-0050/eeprom').slice(0x12,0x1e).toString().toLowerCase());")
echo "MAC address (X.509 CN) is ${SMALLMAC}"

# Check for the initial unit data partition
BOOT0TYPE=$(file -b -s ${EMMC_RO})
if [ "${BOOT0TYPE}" == "data" ]; then
    echo "Missing rodata partition but will not build"
   #while true; do
        msg "$(date -Is) Missing rodata partition but will not create"
        echo "Missing rodata partition but will not create $(date -Is)" > /tmp/olymsg.txt
        zcat /opt/install/missing.fb0.gz > /dev/fb0
        sleep 10
   #done
else
    echo "rodata partition already built"
    echo "FLASHEE PID=$$ : rodata exist $(date -R | sed 's/.*\([0-9][0-9]:[0-9][0-9]:[0-9][0-9]\).*/\1/')" > /tmp/olymsg.txt
    wall "FLASHEE PID=$$ : rodata exist $(date -R | sed 's/.*\([0-9][0-9]:[0-9][0-9]:[0-9][0-9]\).*/\1/')"

    mount ${EMMC_RO} /mnt/rodata
    # Copy the rodata information to the mount point in case the filesystem does not mount
    cp /mnt/rodata/* /mnt/emmc/mnt/rodata/
    umount /mnt/rodata
fi


############################################################################################################
# Attempt to mount any existing image to save the config.json file.
mount -t vfat /dev/mmcblk0p2 /mnt/sdcard

#TC mod - save off FAT partition contents on /vfat for later copying to installed rootf
mkdir -p /vfat
cp -R /mnt/sdcard/* /vfat
#TC mod end

echo "If an existing config file is present, save it to the FAT partion."
if mount /dev/${EMMC_DEV}p1 /mnt/emmc; then
    echo "Attempting backup of the config file to the SD card."
    echo "Source directory:"
    ls -la /mnt/emmc/opt/olympia/node-red/context/global
    echo "cp /mnt/emmc/opt/olympia/node-red/context/global/global.json /mnt/sdcard/save_config.json"
    cp /mnt/emmc/opt/olympia/node-red/context/global/global.json /mnt/sdcard/save_config.json
    cp /mnt/emmc/opt/olympia/node-red/context/global/global.json.backup /mnt/sdcard/previous_config.json
    echo "SD card after copying:"
    ls -la /mnt/sdcard
    echo " "
    echo umount /dev/${EMMC_DEV}p1
    umount /dev/${EMMC_DEV}p1
else
    echo "No existing emmc partiton found.  No backup."
    echo " "
fi
echo umount /dev/mmcblk0p2
umount /dev/mmcblk0p2

############################################################################################################
echo "Start copying partions, U-Boot first, then rootfs"

# Scan for the newly created partition
partprobe

# if statements allow bypass in testing
if true; then
    # Program U-Boot
    zcat /opt/install/CopyUBoot.fb0.gz > /dev/fb0
    echo ' '
    echo '## INFO ## Flashing u-boot to SPI Flash'
    echo "FLASHEE PID=$$ : Flash u-boot 1 min $(date -R | sed 's/.*\([0-9][0-9]:[0-9][0-9]:[0-9][0-9]\).*/\1/')" > /tmp/olymsg.txt
    msg "$(date -Is) Flashing spi-uboot"
    time flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=50000 -w /opt/install/spi-uboot
else
    echo Skipping flash of u-boot.
    zcat /opt/install/CopyUBoot.fb0.gz > /dev/fb0
    sleep 5
fi

if true; then
    # Program the rootfs to the main partition
    zcat /opt/install/CopyRootFS.fb0.gz > /dev/fb0
    echo 'FLASHEE PID=$$ : ## INFO ## Flashing ${EMMC_BASE}p1 eMMC Linux boot partition. Takes about 8 minutes' > /tmp/olymsg.txt
    msg "$(date -Is) Flashing Linux"
    start_time="$(date -u +%s)"
    # The next line must be manually updated to reflect the rootfs source
    # There probably isn't a need to update rootfs as a roll back can be updated to the latest
    ROOTFS_VER=rootfs-20310801.xz.rescue
    time cat /opt/install/rootfs.xz|unxz|dd of=${EMMC_BASE}p1 bs=1M status=progress
    end_time="$(date -u +%s)"
    elapsed="$(($end_time-$start_time))"
else
    zcat /opt/install/CopyRootFS.fb0.gz > /dev/fb0
    echo Skipping flash of RootFS.
    sleep 5
fi


############################################################################################################
msg "$(date -Is) Create machine unique links"
echo '## INFO ## Create machine unique links.'
echo 'FLASHEE PID=$$ : ## INFO ## Create machine unique links.' > /tmp/olymsg.txt

# Mount freshly copied rootfs to clean it up
echo mkdir -p /mnt/emmc && mount /dev/${EMMC_DEV}p1 /mnt/emmc
mkdir -p /mnt/emmc && mount /dev/${EMMC_DEV}p1 /mnt/emmc
mkdir -p /mnt/emmc/vfat
cp -R /vfat/* /mnt/emmc/vfat

############################################################################################################
# Overwrite the old Linux version so we can't get the boot loop of death (BLoD).
# BLoD results when the uInitrd symlink gets moved to point to the old Linux.

pushd /mnt/emmc/boot
if [-f copied-rt49-back]; then
    echo "rt49 version of linux already copied over previous."
else
    echo "Copying rt49 version of linux over previous."
    mv config-4.14.84-sunxi config-4.14.84-sunxi.ori
    cp config-4.14.84-sunxi-rt49+ config-4.14.84-sunxi

    mv dtb-4.14.84-sunxi dtb-4.14.84-sunxi.ori
    cp -r dtb-4.14.84-sunxi-rt49+ dtb-4.14.84-sunxi

    mv System.map-4.14.84-sunxi System.map-4.14.84-sunxi.ori
    cp System.map-4.14.84-sunxi-rt49+ System.map-4.14.84-sunxi

    mv uInitrd-4.14.84-sunxi uInitrd-4.14.84-sunxi.ori
    cp uInitrd-4.14.84-sunxi-rt49+ uInitrd-4.14.84-sunxi

    mv vmlinuz-4.14.84-sunxi vmlinuz-4.14.84-sunxi.ori
    cp vmlinuz-4.14.84-sunxi-rt49+ vmlinuz-4.14.84-sunxi

    touch copied-rt49-back
fi
popd

cd /mnt/emmc/opt

# request to run update_on_boot.sh
#echo $(date -R) > /mnt/emmc/var/lib/olympia/update_on_boot
#curl http://192.168.97.48:1880/get_rootfs_ver | sed 's/.*-> //' > /mnt/emmc/var/lib/olympia/rootfs_ver.txt
# manually updated to match rootfs.xz
echo $ROOTFS_VER > /mnt/emmc/var/lib/olympia/rootfs_ver.txt

# create symlink to Alexa crendential
# symlinks to Alexa crendentials already exist in the image.
#ln -s /mnt/rodata/device.crt   /mnt/emmc/var/lib/olympia/cert.crt
#ln -s /mnt/rodata/privkey.key  /mnt/emmc/var/lib/olympia/private.key
#ln -s /mnt/rodata/root.crt.txt /mnt/emmc/var/lib/olympia/root.crt.txt
echo SMALLMAC is ${SMALLMAC}.  Echoing to /mnt/emmc/var/lib/olympia/endpointId.txt
echo "Olympia_${SMALLMAC}" > /mnt/emmc/var/lib/olympia/endpointId.txt

# The olympia developer key is already present in the image.
mkdir /mnt/emmc/root/.ssh
chmod 700 /mnt/emmc/root/.ssh
touch /mnt/emmc/root/.ssh/authorized_keys
chmod 644 /mnt/emmc/root/.ssh/authorized_keys

# LCD touch calibration file is already present in the image.

############################################################################################################
if true; then
    # unconditionally update APM, HSR and MSP.
    zcat /opt/install/UpdateAPM.fb0.gz > /dev/fb0
    msg "$(date -Is) Update APM"
    echo 'FLASHEE PID=$$ : ## INFO ## Update APM.' > /tmp/olymsg.txt
    echo '## INFO ## Update APM'

    pushd /opt/olympia/apm
    ./updateAPM.sh APM-119_v253_signed.rom
    popd
else
    echo skipping update of APM.
fi

sync
echo ' '
sleep 5
echo ' '

if true; then
    zcat /opt/install/UpdateHSR.fb0.gz > /dev/fb0
    msg "$(date -Is) Update HSR"
    echo '## INFO ## Update HSR'
    echo 'FLASHEE PID=$$ : ## INFO ## Update HSR.' > /tmp/olymsg.txt

    pushd /opt/olympia/hsr
    ./fw_hdmi -fw_hdmi hsr82t_revC_v73r50r34_AddToFlashwriter.hex
    popd
else
    echo Skipping update of HSR
fi

sync
echo ' '
sleep 5
echo ' '

############################################################################################################
msg "$(date -Is) Cleaning /var/log/"
echo '## INFO ## Cleaning /var/log/'
echo 'FLASHEE PID=$$ : ## INFO ## Clearing Logs.' > /tmp/olymsg.txt

# clean log partition
echo clean log partition
rm -rf /mnt/emmc/var/log/olympia/*
rm -rf /mnt/emmc/var/log/*
mkdir -p /mnt/emmc/var/log/olympia

# clean bash history
rm /root/.bash_history

cd
sync
umount /dev/${EMMC_DEV}p1

# sign my work
#echo eMMC created by olyprodsvr version $FLASHER_VER
#echo "FLASHEE PID=$$ : Remove sdcard and power cycle $(date -R | sed 's/.*\([0-9][0-9]:[0-9][0-9]:[0-9][0-9]\).*/\1/') took $elapsed sec" > /tmp/olymsg.txt
#wall "FLASHEE PID=$$ : Remove sdcard and power cycle $(date -R | sed 's/.*\([0-9][0-9]:[0-9][0-9]:[0-9][0-9]\).*/\1/') took $elapsed sec"
#msg "$(date -Is) Rescue complete.  Remove sdcard and power cycle"

sync

# I am skipping this because it seems to often fail in this context.
# The unit must have a good backplane to get this far.
if false; then
    # Must be last, machine can be reset by this.
    # Is there an easy way to read the version from the script and avoid the update?
    zcat /opt/install/Update430.fb0.gz > /dev/fb0
    msg "$(date -Is) Update Backplane"
    echo '## INFO ## Update Backplane'
    echo 'FLASHEE PID=$$ : ## INFO ## Update Backplane.' > /tmp/olymsg.txt

    cd /opt/olympia/int3p
    # turn off watchdog
    echo './stroke430 0' to disable watchdog
    ./stroke430 0
    #give it a moment to act.
    echo sleep 5
    echo './update430 -v Eq3PowerMCU_update_v51.txt' to program backplane
    ./update430 -v Eq3PowerMCU_update_v51.txt
    echo sleep 5
    sleep 5
else
    echo Skipping update of backplane.
fi

zcat /opt/install/Reboot.fb0.gz > /dev/fb0

if true; then
    echo "Update script completed. You can reboot now."
    echo "Front panel says remove SD card and power cycle."
    msg "$(date -Is) Update script completed. Power off, Remove SD card, Power on."
    echo 'FLASHEE PID=$$ : ## INFO ## Update script completed. Power off, Remove SD card, Power on.' > /tmp/olymsg.txt
    sync
else
    # if you auto reboot, the SD card is still in and the whole thing runs again.
    echo "Update script completed. The system should reboot in a few seconds."
    echo './stroke430 10' for reboot.
    /opt/olympia/int3p/stroke430 10
    sync
    # let the display last for a few seconds.
    sleep 5
    # turn off front panel so it doesn't fade.
    echo Turn off backlight
    echo 1 > /sys/class/backlight/backlight/bl_power    
    echo shutdown now
    shutdown now
fi
            
