# Changelog


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
