PXE_TEMP_IP:=192.168.1.250
PXE_TFTP:=192.168.1.231


GRUB_ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
CORES:=$(shell nproc)
SHELL:=/bin/bash

# docker file to build
DOCKERFILE:=$(GRUB_ROOT_DIR)/docker/Dockerfile.ubuntu2004
DOCKERIMAGE:=hradec/ipxe-buid-ubuntu:20.04
DOCKERFILE:=$(GRUB_ROOT_DIR)/docker/Dockerfile
DOCKERIMAGE:=hradec/ipxe-buid-debian:11

# we use uid and gid to keep files with the correct permissions, since docker
# runs as root user!
UID=$(shell id -u)
GID=$(shell id -g)

# by default, run this makefile in the docker build environment
all: grub_menu $(GRUB_ROOT_DIR)/grub_boot_defaults

vmlinuz:=$(shell readlink -f $(GRUB_ROOT_DIR)/../vmlinuz)
initrd:=$(shell readlink -f $(GRUB_ROOT_DIR)/../initrd)
$(GRUB_ROOT_DIR)/ipxe/git/src/vmlinuz: ${vmlinuz}
	cp -Lvu ${vmlinuz} $(GRUB_ROOT_DIR)/ipxe/git/src/vmlinuz
$(GRUB_ROOT_DIR)/ipxe/git/src/initrd: ${initrd}
	cp -Lvu ${initrd} $(GRUB_ROOT_DIR)/ipxe/git/src/initrd


$(GRUB_ROOT_DIR)/grub_make_efi/vmlinuz:
	cp -Lvu ${vmlinuz} $(GRUB_ROOT_DIR)/grub_make_efi/vmlinuz
$(GRUB_ROOT_DIR)/grub_make_efi/initrd:
	cp -Lvu ${initrd} $(GRUB_ROOT_DIR)/grub_make_efi/initrd


$(GRUB_ROOT_DIR)/grub.cfg: $(GRUB_ROOT_DIR)/grub_template_menu.cfg $(GRUB_ROOT_DIR)/grub_boot_defaults
	echo >  $(GRUB_ROOT_DIR)/grub.cfg
	egrep 'timeout|default' $(GRUB_ROOT_DIR)/grub_template_menu.cfg >> $(GRUB_ROOT_DIR)/grub.cfg
	cat $(GRUB_ROOT_DIR)/grub_boot_defaults | while read l ; do m=$$(echo $$l | awk '{print tolower($$1)}');d=$$(echo $$l | awk '{print $$2}');t=$$(echo $$l | awk '{print $$3}');h=$$(echo $$l | awk '{print $$4}');echo -e "if [ x\$${net_ne0_mac} == x$$m -o x\$${net_ne1_mac} == x$$m ]; then set timeout=$$t ; set default=$$d ; fi # hostname: $$h" ; done >>  $(GRUB_ROOT_DIR)/grub.cfg 
	egrep -v 'timeout|default'  $(GRUB_ROOT_DIR)/grub_template_menu.cfg | grep -v '#' | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g" >> $(GRUB_ROOT_DIR)/grub.cfg


$(GRUB_ROOT_DIR)/grub.booti386: $(GRUB_ROOT_DIR)/grub.cfg $(GRUB_ROOT_DIR)/grub_template_bios.cfg $(GRUB_ROOT_DIR)/grub_make_bios/build.sh $(GRUB_ROOT_DIR)/grub_make_bios/early_grub.cfg
	cat $(GRUB_ROOT_DIR)/grub_template_bios.cfg | grep -v '#' | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g" > $(GRUB_ROOT_DIR)/grub_make_bios/grub.cfg
	#cat $(GRUB_ROOT_DIR)/grub_template_menu.cfg | grep -v '#' | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g" >> $(GRUB_ROOT_DIR)/grub_make_bios/grub.cfg
	#cat $(GRUB_ROOT_DIR)/grub_template_menu.cfg | grep -v '#' | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g" > $(GRUB_ROOT_DIR)/grub_make_bios/grub_menu.cfg
	cd $(GRUB_ROOT_DIR)/grub_make_bios && ./build.sh

$(GRUB_ROOT_DIR)/grub.efi: $(GRUB_ROOT_DIR)/grub.cfg $(GRUB_ROOT_DIR)/grub_template_efi.cfg $(GRUB_ROOT_DIR)/grub_make_efi/build.sh
	cat $(GRUB_ROOT_DIR)/grub_template_efi.cfg  | grep -v '#' | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g"  > $(GRUB_ROOT_DIR)/grub_make_efi/grub.cfg
	cat $(GRUB_ROOT_DIR)/grub_make_efi/grub.cfg > $(GRUB_ROOT_DIR)/grub_make_efi/boot/grub/grub.cfg && \
	cat $(GRUB_ROOT_DIR)/grub.cfg >> $(GRUB_ROOT_DIR)/grub_make_efi/boot/grub/grub.cfg && \
	cd $(GRUB_ROOT_DIR)/grub_make_efi && ./build.sh && cd .. && \
	mkdir -p $(GRUB_ROOT_DIR)/./OSX/grub.nbi/i386 && sudo cp -rf $(GRUB_ROOT_DIR)/grub.* $(GRUB_ROOT_DIR)/./OSX/grub.nbi/i386

$(GRUB_ROOT_DIR)/.build_docker_image:
	cd $(GRUB_ROOT_DIR)/docker/ &&\
	docker build . -f $(DOCKERFILE) -t $(DOCKERIMAGE)
	touch $(GRUB_ROOT_DIR)/.build_docker_image

clean:
	rm -f $(GRUB_ROOT_DIR)/grub.*
	rm -f $(GRUB_ROOT_DIR)/ipxe.*
	rm -f $(GRUB_ROOT_DIR)/grub_make_efi/grub.*
	rm -f $(GRUB_ROOT_DIR)/grub_make_bios/*.tar
	rm -f $(GRUB_ROOT_DIR)/grub_make_bios/grub.*
	rm -f $(GRUB_ROOT_DIR)/grub_make_bios/_*
	rm -f $(GRUB_ROOT_DIR)/.done
	rm -f $(GRUB_ROOT_DIR)/.build_docker_image
	rm -f $(GRUB_ROOT_DIR)/.grub
	rm -f $(GRUB_ROOT_DIR)/.ipxe

nuke: clean distclean
distclean: clean
	rm -rf $(GRUB_ROOT_DIR)/OSX
	rm -rf $(GRUB_ROOT_DIR)/ipxe
	rm -rf $(GRUB_ROOT_DIR)/grub/git


STUDIO:=$(shell dirname `ls  /*/.root` 2>/dev/null)
DEFAULT_BOOT:=$(shell egrep '^set default' $(GRUB_ROOT_DIR)/grub_template_menu.cfg  | awk -F'=' '{print $$2}')
DEFAULT_TIMEOUT:=$(shell egrep '^set timeout' $(GRUB_ROOT_DIR)/grub_template_menu.cfg  | awk -F'=' '{print $$2}')
grub_menu: $(GRUB_ROOT_DIR)/.build_docker_image $(GRUB_ROOT_DIR)/grub_make_efi/vmlinuz $(GRUB_ROOT_DIR)/grub_make_efi/initrd $(GRUB_ROOT_DIR)/grub_boot_defaults grub $(GRUB_ROOT_DIR)/ipxe/git/src/vmlinuz
	touch $(GRUB_ROOT_DIR)/grub_boot_defaults
	cat $(STUDIO)/pipeline/tools/init/hosts | while read line ; do \
		mac=$$(echo  $$line | awk -F' ' '{print $$1}') ;\
		host=$$(echo $$line | awk -F' ' '{print $$2}') ;\
		search=$$(grep "$$mac" $(GRUB_ROOT_DIR)/grub_boot_defaults) ;\
		if [ "$$search" == "" ] ; then \
			echo -e "$$mac\t$(DEFAULT_BOOT)\t$(DEFAULT_TIMEOUT)\t$$host" >> $(GRUB_ROOT_DIR)/grub_boot_defaults ;\
		fi ;\
	done
	cat $(GRUB_ROOT_DIR)/grub_boot_defaults
	#cp $(readlink -f /root/docker/pxe-manager/tftp/vmlinuz) $(GRUB_ROOT_DIR)/grub_make_bios/vmlinuz
	#cp $(readlink -f /root/docker/pxe-manager/tftp/initrd)  $(GRUB_ROOT_DIR)/grub_make_bios/initrd
	docker run \
		--rm \
		--privileged=true \
		-v $(GRUB_ROOT_DIR)/:$(GRUB_ROOT_DIR)/ \
		$(DOCKERIMAGE) \
		/bin/bash -c 'cd $(GRUB_ROOT_DIR)/ && make UID=$(UID) GID=$(GID) docker_build_grub_menu'

# this is the actual build entry running inside docker
docker_build_grub_menu: $(GRUB_ROOT_DIR)/grub.efi $(GRUB_ROOT_DIR)/grub.booti386 docker_build_ipxe
	chown -R $(UID):$(GID) $(GRUB_ROOT_DIR)/grub.*
	chown -R $(UID):$(GID) $(GRUB_ROOT_DIR)/grub_make_efi/grub.*
	chown -R $(UID):$(GID) $(GRUB_ROOT_DIR)/grub_make_bios/grub.*
	chown -R $(UID):$(GID) $(GRUB_ROOT_DIR)/OSX/


# =========================================================================================================================================================
# build grub from git
# =========================================================================================================================================================
grub: $(GRUB_ROOT_DIR)/grub/git-install-pc-i386/bin/grub-mkstandalone $(GRUB_ROOT_DIR)/grub/git-install-efi-i386/bin/grub-mkstandalone $(GRUB_ROOT_DIR)/grub/git-install-pc-x86_64/bin/grub-mkstandalone $(GRUB_ROOT_DIR)/grub/git-install-efi-x86_64/bin/grub-mkstandalone

$(GRUB_ROOT_DIR)/grub/git-install-pc-i386/bin/grub-mkstandalone: $(GRUB_ROOT_DIR)/.build_docker_image
	docker run  --rm --privileged=true -v $(GRUB_ROOT_DIR)/:$(GRUB_ROOT_DIR)/ $(DOCKERIMAGE) /bin/bash -c 'cd $(GRUB_ROOT_DIR)/ && make UID=$(UID) GID=$(GID) $(GRUB_ROOT_DIR)/grub/git-install-pc-i386/bin/grub-mkimage'
	touch $@

$(GRUB_ROOT_DIR)/grub/git-install-efi-i386/bin/grub-mkstandalone: $(GRUB_ROOT_DIR)/.build_docker_image
	docker run  --rm --privileged=true -v $(GRUB_ROOT_DIR)/:$(GRUB_ROOT_DIR)/ $(DOCKERIMAGE) /bin/bash -c 'cd $(GRUB_ROOT_DIR)/ && make UID=$(UID) GID=$(GID) $(GRUB_ROOT_DIR)/grub/git-install-efi-i386/bin/grub-mkimage'
	touch $@

$(GRUB_ROOT_DIR)/grub/git-install-pc-x86_64/bin/grub-mkstandalone: $(GRUB_ROOT_DIR)/.build_docker_image
	docker run  --rm --privileged=true -v $(GRUB_ROOT_DIR)/:$(GRUB_ROOT_DIR)/ $(DOCKERIMAGE)  /bin/bash -c 'cd $(GRUB_ROOT_DIR)/ && make UID=$(UID) GID=$(GID) $(GRUB_ROOT_DIR)/grub/git-install-pc-x86_64/bin/grub-mkimage'
	touch $@

$(GRUB_ROOT_DIR)/grub/git-install-efi-x86_64/bin/grub-mkstandalone: $(GRUB_ROOT_DIR)/.build_docker_image
	docker run  --rm --privileged=true -v $(GRUB_ROOT_DIR)/:$(GRUB_ROOT_DIR)/ $(DOCKERIMAGE)  /bin/bash -c 'cd $(GRUB_ROOT_DIR)/ && make UID=$(UID) GID=$(GID) $(GRUB_ROOT_DIR)/grub/git-install-efi-x86_64/bin/grub-mkimage'
	touch $@


#docker_build_grub: $(GRUB_ROOT_DIR)/grub/git-install-efi-i386/bin/grub-mkimage $(GRUB_ROOT_DIR)/grub/git-install-efi-x86_64/bin/grub-mkimage $(GRUB_ROOT_DIR)/grub/git-install-pc-i386/bin/grub-mkimage $(GRUB_ROOT_DIR)/grub/git-install-pc-x86_64/bin/grub-mkimage

$(GRUB_ROOT_DIR)/grub/git:
	if [ ! -e $(GRUB_ROOT_DIR)/grub/git ] ; then \
		mkdir -p grub \
		&& git clone --recursive --depth=1 https://git.savannah.gnu.org/git/grub.git  $(GRUB_ROOT_DIR)/grub/git \
		&& cd $(GRUB_ROOT_DIR)/grub/git \
		&& git fetch --tags \
		&& lastest_tag=$$(git describe --tags $$(git rev-list --tags --max-count=1)) \
		&& echo $$lastest_tag \
		&& echo git checkout tags/$$lastest_tag -b $$lastest_tag \
	; fi

$(GRUB_ROOT_DIR)/grub/git/configure: $(GRUB_ROOT_DIR)/grub/git
	cd $(GRUB_ROOT_DIR)/grub/git &&\
	if [ ! -e $(GRUB_ROOT_DIR)/grub/git/configure ] ; then ./bootstrap ; fi

#GRUB_BUILD_EXTRA_CONFIGURE:=" --enable-device-mapper "
$(GRUB_ROOT_DIR)/grub/git-install-efi-i386/bin/grub-mkimage: $(GRUB_ROOT_DIR)/grub/git/configure
	cd $(GRUB_ROOT_DIR)/grub/git &&\
	make clean ;\
	./configure $(GRUB_BUILD_EXTRA_CONFIGURE) --with-platform=efi --target=i386 --disable-werror --prefix=$(GRUB_ROOT_DIR)/grub/git-install-efi-i386 && \
	make -j $(CORE) ; make -j $(CORE) install

$(GRUB_ROOT_DIR)/grub/git-install-efi-x86_64/bin/grub-mkimage: $(GRUB_ROOT_DIR)/grub/git/configure
	cd $(GRUB_ROOT_DIR)/grub/git &&\
	make clean ;\
	./configure $(GRUB_BUILD_EXTRA_CONFIGURE) --with-platform=efi --target=x86_64 --disable-werror --prefix=$(GRUB_ROOT_DIR)/grub/git-install-efi-x86_64 &&\
	make -j $(CORE) ; make -j $(CORE) install

$(GRUB_ROOT_DIR)/grub/git-install-pc-i386/bin/grub-mkimage: $(GRUB_ROOT_DIR)/grub/git/configure
	cd $(GRUB_ROOT_DIR)/grub/git &&\
	make clean ;\
	./configure $(GRUB_BUILD_EXTRA_CONFIGURE) --with-platform=pc  --target=i386   --disable-werror --prefix=$(GRUB_ROOT_DIR)/grub/git-install-pc-i386    &&\
	make -j $(CORE) ; make -j $(CORE) install

$(GRUB_ROOT_DIR)/grub/git-install-pc-x86_64/bin/grub-mkimage: $(GRUB_ROOT_DIR)/grub/git/configure
	cd $(GRUB_ROOT_DIR)/grub/git &&\
	make clean ;\
	./configure $(GRUB_BUILD_EXTRA_CONFIGURE) --with-platform=pc  --target=x86_64 --disable-werror --prefix=$(GRUB_ROOT_DIR)/grub/git-install-pc-x86_64  &&\
	make -j $(CORE) ; make -j $(CORE) install


# =========================================================================================================================================================
# build ipxe from git
# =========================================================================================================================================================
ipxe: $(GRUB_ROOT_DIR)/ipxe.booti386

$(GRUB_ROOT_DIR)/ipxe.booti386: $(GRUB_ROOT_DIR)/.build_docker_image $(GRUB_ROOT_DIR)/Makefile $(GRUB_ROOT_DIR)/grub_boot_defaults
	docker run \
                --rm \
                --privileged=true \
                -v $(GRUB_ROOT_DIR)/:$(GRUB_ROOT_DIR)/ \
                $(DOCKERIMAGE) \
                /bin/bash -c 'cd $(GRUB_ROOT_DIR)/ && make UID=$(UID) GID=$(GID) docker_build_ipxe'
	chown -R $(UID):$(GID) $(GRUB_ROOT_DIR)/ipxe.booti386
	touch $(GRUB_ROOT_DIR)/ipxe.booti386

docker_build_ipxe_git:
	if [ ! -e $(GRUB_ROOT_DIR)/ipxe/git/src ] ; then \
		mkdir -p ipxe ;\
		git clone --recursive https://github.com/ipxe/ipxe.git  $(GRUB_ROOT_DIR)/ipxe/git/ ;\
	fi
		cd $(GRUB_ROOT_DIR)/ipxe/git/ ;\
		git fetch --tags ;\
		lastest_tag=$$(git describe --tags $$(git rev-list --tags --max-count=1)) &&\
		echo $$lastest_tag &&\
		git checkout HEAD && \
		git checkout tags/$$lastest_tag

# convert grub_template_menu to a simple ipxe menu
MENU_DEFAULT:=$(shell echo $(grep default $(GRUB_ROOT_DIR)/grub_template_menu.cfg | awk -F'=' '{print $2}'))
MENU_DEFAULT:=1
$(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe: docker_build_ipxe_git
	rm -rf $(GRUB_ROOT_DIR)/ipxe/git/src/menu
	echo -e "#!ipxe\n" > $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe
	echo -e 'echo IP address: $${net0/ip} ; echo Subnet mask: $${net0/netmask} ;echo ' >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe
	echo -e "\n:retry_dhcp\ndhcp -t $$(( 60 * 60 * 1 )) || goto retry_dhcp\n" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe
	grub=$$(egrep -v '#|echo' $(GRUB_ROOT_DIR)/grub_template_menu.cfg) ; \
	for n in $$(echo -e "$$grub" | grep menuentry | awk -F"'" '{print $$2}' | sed 's/ /./g') ; do \
		kernel=$$(echo -e "$$grub" | grep "$$n" -A5 | grep linux  | awk -F'linux ' '{print $$2}' | sed 's/PXE_TFTP/$(PXE_TFTP)/g') ; \
		initrd=$$(echo -e "$$grub" | grep "$$n" -A5 | grep initrd | awk -F'initrd ' '{print $$2}' | sed 's/PXE_TFTP/$(PXE_TFTP)/g') ; \
		if [ "$$(echo -e $$n | grep -i windows)" != "" ] ; then \
			echo -e "$$n@@" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu ; \
		fi ; \
		if [ "$$kernel" != "" ] ; then \
			echo -e "$$n@$$kernel@$$initrd" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu ; \
		fi ; \
	done
	echo -e 'goto $${mac:hexraw} || goto mac_default' >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe
	cat $(GRUB_ROOT_DIR)/grub_boot_defaults | while read each ; do \
		m=$$(echo $$each | awk '{print $$1}') ;\
		d=$$(echo $$each | awk '{print $$2}') ;\
		d=$$(sed $$(echo $$(( $$d+1 )) | awk '{print $$1"!d"}') $(GRUB_ROOT_DIR)/ipxe/git/src/menu | awk -F'@' '{print $$1}') ;\
		echo $$d ; \
		echo -e ":$$(echo $${m,,} | sed 's/://g')" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe ;\
		echo -e "set default $$d" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe ;\
		echo -e "goto start" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe ;\
	done
	echo -e ":mac_default" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe
	echo -e "set default $$(sed $$(echo $$(( $(MENU_DEFAULT)+1 )) | awk '{print $$1"!d"}') $(GRUB_ROOT_DIR)/ipxe/git/src/menu | awk -F'@' '{print $$1}')\n" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe ;\
	\
	echo -e ":start" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe ;\
	echo -e 'menu iPXE boot menu ($${net0/ip})\nitem --gap --' >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe ;\
	cat $(GRUB_ROOT_DIR)/ipxe/git/src/menu | while read m ; do \
		item=$$(echo -e "$$m" | awk -F'@' '{print $$1}') ; \
		echo -e "item $$item\t$$item" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe ; \
	done
	timeout=$$(grep timeout $(GRUB_ROOT_DIR)/grub_template_menu.cfg | grep -v '#' | awk -F'=' '{print $$2}') ; \
	t=$$(( $$timeout * 1000 )) ; \
	echo -e -n "choose --timeout $$t " >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe
	echo -e '--default $${default} selected' >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe
	echo -e 'set menu-timeout 0' >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe
	echo -e 'goto $${selected}\n' >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe
	cat $(GRUB_ROOT_DIR)/ipxe/git/src/menu | while read m ; do \
		item=$$(echo -e "$$m" | awk -F'@' '{print $$1}') ; \
		k=$$(echo -e "$$m" | awk -F'@' '{print $$2}' | awk '{print $$1}') ; \
		i=$$(echo -e "$$m" | awk -F'@' '{print $$3}') ; \
		a=$$(echo -e "$$m" | awk -F'@' '{print $$2}' | awk -F"$$k " '{print $$2}') ; \
		if [ "$$(echo -e $$item | grep -i windows)" != "" ] ; then \
			echo -e ":$$item\ngoto exit_ipxe\n" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe ; \
		else \
			echo -e ":$$item" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe ; \
			echo -e 'echo IP address: $${net0/ip} ; echo Subnet mask: $${net0/netmask} ;echo ' >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe ; \
			echo -e "kernel tftp://$(PXE_TFTP)/$$k || shell" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe ; \
			echo -e "initrd tftp://$(PXE_TFTP)/$$i" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe ; \
			echo -e "imgargs $$(basename $$k) $$a\nboot || sleep 600\ngoto start\n" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe ; \
		fi ; \
	done
	echo -e ':exit_ipxe\n\n' >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe

# this is the actual build entry running inside docker
#DEBUG_EFI:=" DEBUG=efi_image "
DEBUG_EFI:=" DEBUG=efi_driver,snpnet,pci,efi_pxe,efi_pci,ipv4 "
#DEBUG_EFI:=" DEBUG=netdevice "
ipxe_chainload_filename:=grub-netboot-git/grub.booti386
docker_build_ipxe: $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe
	gcc --version
	args=$(grep 'linux'  $(GRUB_ROOT_DIR)/grub.cfg  | head -1 | sed 's/linux.*vmlinuz//') && \
	echo  -e  "#!ipxe\
		\n#:retry_dhcp\
		\n#dhcp || goto retry_dhcp\
		\n\
		\necho Booting from $(ipxe_chainload_filename)\
		\necho IP address: ${net0/ip} ; echo Subnet mask: ${net0/netmask} \
		\n#chain tftp://$(PXE_TFTP)/$(ipxe_chainload_filename)\
		\nkernel vmlinuz\
		\ninitrd initrd\
		\nimgargs vmlinuz $$args \
		\n#boot\
		\nexit\
	" > $(GRUB_ROOT_DIR)/ipxe/git/src/demo.ipxe
	cp $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe $(GRUB_ROOT_DIR)/ipxe/git/src/demo.ipxe
	cat $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe  | sed 's/tftp.\/\/.*\///' | sed 's/dhcp -t/#dhcp/' > $(GRUB_ROOT_DIR)/ipxe/git/src/menu_with_linux.ipxe
	cd $(GRUB_ROOT_DIR)/ipxe/git/src &&\
	echo make clean &&\
	echo LANG=C make NO_WERROR=1 -j $(CORE) bin-x86_64-efi/ipxe.efi EMBED=$(GRUB_ROOT_DIR)/ipxe/git/src/demo.ipxe $(DEBUG_EFI) &&\
	echo cp $(GRUB_ROOT_DIR)/ipxe/git/src/bin-x86_64-efi/ipxe.efi $(GRUB_ROOT_DIR)/ipxe.efi && \
	echo make clean &&\
	echo LANG=C make NO_WERROR=1 -j $(CORE) bin-x86_64-efi/ipxe.efi EMBED=$(GRUB_ROOT_DIR)/ipxe/git/src/menu_with_linux.ipxe,vmlinuz,initrd $(DEBUG_EFI) &&\
	echo cp $(GRUB_ROOT_DIR)/ipxe/git/src/bin-x86_64-efi/ipxe.efi $(GRUB_ROOT_DIR)/ipxe_with_linux.efi && \
	echo make clean &&\
	LANG=C make NO_WERROR=1 -j $(CORE) bin/undionly.kpxe EMBED=$(GRUB_ROOT_DIR)/ipxe/git/src/demo.ipxe &&\
	cp $(GRUB_ROOT_DIR)/ipxe/git/src/bin/undionly.kpxe $(GRUB_ROOT_DIR)/ipxe.booti386


#	make clean &&\
#	LANG=C make NO_WERROR=1 -j $(CORE) bin-x86_64-efi/snponly.efi EMBED=$(GRUB_ROOT_DIR)/ipxe/git/src/demo.ipxe,vmlinuz,initrd $(DEBUG_EFI) &&\
#	cp $(GRUB_ROOT_DIR)/ipxe/git/src/bin-x86_64-efi/snponly.efi $(GRUB_ROOT_DIR)/snponly.efi && \


