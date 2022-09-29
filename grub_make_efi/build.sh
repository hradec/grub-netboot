#!/bin/bash


CD=$(readlink -f $(dirname $BASH_SOURCE))
cd $CD

GRUB=$CD/../grub/git-install-efi-x86_64/

core=x86_64-efi
#core=ia64-efi

mkstandalone=$(ls $GRUB/bin/grub*mkstand*)
$mkstandalone \
	--disable-shim-lock \
        -d $GRUB/lib/grub/x86_64-efi/   \
        -O $core  \
        --fonts="unicode"  \
        -o ../grub.efi \
	fakebios \
	time \
        at_keyboard \
        usb_keyboard \
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
	memdisk tar tftp reboot efinet vmlinuz initrd \
        configfile boot/grub/grub.cfg

#        pxe \
#        pxechain \
