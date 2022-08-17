#!/bin/bash

CD=$(readlink -f $(dirname $BASH_SOURCE))
cd $CD

GRUB=$CD/../grub/git-install-pc-i386/
mkimage=$(ls  $GRUB/bin/grub*mkimage)

#cp $(readlink -f /root/docker/pxe-manager/tftp/vmlinuz) ./vmlinuz
#cp $(readlink -f /root/docker/pxe-manager/tftp/initrd) ./initrd
tar cf memdisk.tar grub.cfg


type=i386-pc-pxe
#type=i386-coreboot
#config=boot/grub/grub.cfg
config=_early_grub.cfg
touch _early_grub.cfg
grep insmod grub.cfg > _early_grub.cfg
cat early_grub.cfg >> _early_grub.cfg
$mkimage -d $GRUB/lib/grub/i386-pc/ \
	-O $type \
	-o ../grub.booti386 \
	-p '/grub' \
        --config $config \
	pxe \
	acpi \
	usb \
	pxechain \
	usbms \
	ntfs \
	ntldr \
        net \
        tftp \
	gzio \
	part_msdos \
	part_gpt \
	hfsplus \
	fat \
	ext2 \
	normal \
	configfile \
	biosdisk \
	multiboot multiboot2 \
	chain boot linux linux16 echo search \
	memdisk tar reboot loopback serial iso9660 \
-m memdisk.tar


#	cat \
#	sleep \
#	parttool \
