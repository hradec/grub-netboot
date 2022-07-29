
PXE_TEMP_IP:=192.168.1.250
PXE_TFTP:=192.168.1.231

GRUB_ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

all: $(GRUB_ROOT_DIR)/.done
$(GRUB_ROOT_DIR)/.done: $(GRUB_ROOT_DIR)/grub_template_menu.cfg $(GRUB_ROOT_DIR)/grub_template_bios.cfg $(GRUB_ROOT_DIR)/grub_template_efi.cfg
	cat $(GRUB_ROOT_DIR)/grub_template_menu.cfg | grep -v '#' | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g" > $(GRUB_ROOT_DIR)/grub.cfg && \
	cat $(GRUB_ROOT_DIR)/grub_template_menu.cfg | grep -v '#' | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g" > $(GRUB_ROOT_DIR)/grub_make_bios/grub_menu.cfg && \
	cat $(GRUB_ROOT_DIR)/grub_template_bios.cfg | grep -v '#' | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g" > $(GRUB_ROOT_DIR)/grub_make_bios/grub.cfg && \
	cat $(GRUB_ROOT_DIR)/grub_template_menu.cfg | grep -v '#' | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g" >> $(GRUB_ROOT_DIR)/grub_make_bios/grub.cfg && \
	cd $(GRUB_ROOT_DIR)/grub_make_bios && ./build.sh && cd .. && \
	cat $(GRUB_ROOT_DIR)/grub_template_efi.cfg | grep -v '#' | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g"  > $(GRUB_ROOT_DIR)/grub_make_efi/grub.cfg && \
	cd $(GRUB_ROOT_DIR)/grub_make_efi && ./build.sh && cd .. && \
	mkdir -p $(GRUB_ROOT_DIR)/./OSX/grub.nbi/i386 && sudo cp -rf $(GRUB_ROOT_DIR)/grub.* $(GRUB_ROOT_DIR)/./OSX/grub.nbi/i386 && \
	touch $(GRUB_ROOT_DIR)/.done


clean:
	rm -f $(GRUB_ROOT_DIR)/grub.*
	rm -f $(GRUB_ROOT_DIR)/grub_make_efi/grub.*
	rm -f $(GRUB_ROOT_DIR)/grub_make_bios/grub.*
	rm -rf $(GRUB_ROOT_DIR)/./OSX
	rm -f $(GRUB_ROOT_DIR)/.done
