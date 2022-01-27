#!/bin/bash


mkimage=$(ls  /usr/bin/grub*mkimage)

CD=$(readlink -f $(dirname $BASH_SOURCE))
cd $CD

$mkimage -d $CD/usr-lib-grub-i386-pc/ -O i386-pc-pxe -o ../grub.booti386 -p '/grub' \
        --config boot/grub/grub.cfg \
	sleep \
	pxe \
	pxechain \
        net \
        tftp \
	gzio \
	part_gpt \
	hfsplus \
	fat \
	ext2 \
	normal \
	configfile \
	chain boot linux linux16 echo search \
	memdisk tar reboot loopback serial iso9660
