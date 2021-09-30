#!/bin/bash


CD=$(readlink -f $(dirname $BASH_SOURCE))
cd $CD

grub-mkimage -d $CD/usr-lib-grub-i386-pc/ -O i386-pc-pxe -o ../grub.booti386 -p '/grub' \
        --config boot/grub/grub.cfg \
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
	chain boot linux echo search \
	memdisk tar reboot \

