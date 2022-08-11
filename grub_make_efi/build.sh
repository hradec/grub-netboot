#!/bin/bash

mkstandalone=$(ls  /usr/bin/grub*mkstand*)

CD=$(readlink -f $(dirname $BASH_SOURCE))
cd $CD

$mkstandalone \
        -d $CD/usr-lib-grub-x86_64-efi/   \
        -O x86_64-efi  \
        --fonts="unicode"  \
        -o ../grub.efi \
        pxe \
        pxechain \
	fakebios \
        usb \
        usbms \
	ntfs \
        ntldr \
        part_msdos \
	net \
	efinet \
	tftp \
	gzio \
	part_gpt \
	efi_gop \
	efi_uga \
	fakebios \
	dhcp \
	part_gpt hfsplus fat ext2 normal chain boot configfile linux linux16 iso9660 loadenv echo \
	search loadbios video_fb videotest pci efi_gop efi_uga font gfxterm font \
	memdisk tar tftp reboot efinet \
        configfile boot/grub/grub.cfg
