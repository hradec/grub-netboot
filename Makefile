
PXE_TEMP_IP=192.168.1.250
PXE_TFTP=192.168.1.230

install:
	cat grub_template_menu.cfg | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g" > grub.cfg
	cat grub_template_bios.cfg | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g" > grub_make_bios/grub.cfg
	cd grub_make_bios && ./build.sh
	cat grub_template_efi.cfg | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g"  > grub_make_efi/grub.cfg
	cd grub_make_efi && ./build.sh
	mkdir -p ./OSX/grub.nbi/i386 && sudo cp -rf grub.* ./OSX/grub.nbi/i386


clean:
	rm grub.*
	rm -rf ./OSX
