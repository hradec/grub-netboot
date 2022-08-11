#!/bin/bash

CD=$(dirname $(readlink -f $0))

mkimage=$(ls  $CD/../git/install/bin/grub*mkimage)

CD=$(readlink -f $(dirname $BASH_SOURCE))
cd $CD

$mkimage -d $CD/../git/install/lib/grub/i386-pc/ -O i386-pc-pxe -o ../grub.booti386 -p '/grub' \
        --config boot/grub/grub.cfg \
	pxe \
	pxechain \
	usbms \
	ntfs \
	ntldr \
	part_msdos \
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


#	sleep \
#	acpi \
#	usb \
