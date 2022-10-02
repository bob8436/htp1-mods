# Changelog

## [1.9.1-mod-r4]
### Changed
- Integrated OLIMEX patch to set min CPU voltage to 1.3v
- Pinned CPU speed to 912mhz

## [1.9.1-mod-r3]
### Added
- README and LICENSE files to vfat partition

### Changed
- HTP-1 upgrade source disabled. No updates on this firmware.

### Removed
- Scripts and artifacts relating to HTP-1 upgrades

## [1.9.1-mod-r2]
### Added
- JSoosiah's custom UI now available at /custom
- JSoosiah's background service runs automatically

### Changed
- Switched to GPT partition layout, ext4 partitions hidden

## [1.9.1-mod-r1]

### Added
- authorized_keys file on FAT32 partition enables SSH login as root

### Changed
- Debian auto upgrades functionality disabled
- Initrd updates disabled
- Modified firmware to run directly from SD-card
- Disabled Log2RAM, added dedicated /var/log partition
- Enabled journal on /var/log
- Disabled all apt repos
- Minor disk space improvements
