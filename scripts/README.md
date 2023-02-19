### Scripts

These are the scripts that modify the HTP-1. Two sets of scripts are run: first,
rootfs scripts, which modify the root filesystem the HTP-1 runs on. Scripts are
run in lexicographic order. The rootfs scripts are run from a chroot such that
the root of the HTP-1 filesystem appars to be /. This means that a command such
as `systemctl disable` would disable a service inside the HTP-1. The htp1-mods
folder is mountedat /htp1-mods.

After resulting root filesystem is exported to an SD-card image, it is further
modified by the installer scripts which customize it to be installed to the
internal flash of an HTP-1. These scripts run without chroot - the filesystem
root of the HTP-1 is available at /htp1-root and the filesystem root of the
SD-card installer (rescue disk) is available at /installer-root. The /htp1-mods
folder is available as well.

#### Assets

Text files that the scripts/transforms may rely on.
