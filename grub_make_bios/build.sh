#!/bin/bash

CD=$(readlink -f $(dirname $BASH_SOURCE))
cd $CD

GRUB=$CD/../grub/git-install-pc-i386/
mkimage=$(ls  $GRUB/bin/grub*mkimage)
$mkimage -d $GRUB/lib/grub/i386-pc/ -O i386-pc-pxe -o ../grub.booti386 -p '/grub' \
        --config boot/grub/grub.cfg \
	pxe \
	sleep \
	acpi \
	usb \
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


