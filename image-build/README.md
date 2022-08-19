### Building a bootable SD Card from scratch

1. use DD to create a zero'd file of appropriate size
2. write uboot at the appropriate place - `dd if=u-boot-sunxi-with-spl.bin of=${card} bs=1024 seek=8 conv=notrunc`
3. Use fdisk to create partition one at sector 8192, partition two after
4. Mount image to multiple partitions using losetup -fP
5. Create ext-4 filesystem on both partitions
6. spin down loopback file, xz the image
