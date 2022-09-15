
PXE_TEMP_IP:=192.168.1.250
PXE_TFTP:=192.168.1.231

GRUB_ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
CORES:=$(shell nproc)

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
all: grub_menu


$(GRUB_ROOT_DIR)/grub.cfg: $(GRUB_ROOT_DIR)/grub_template_menu.cfg
	cat $(GRUB_ROOT_DIR)/grub_template_menu.cfg | grep -v '#' | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g" > $(GRUB_ROOT_DIR)/grub.cfg

$(GRUB_ROOT_DIR)/grub.booti386: $(GRUB_ROOT_DIR)/grub.cfg $(GRUB_ROOT_DIR)/grub_template_bios.cfg $(GRUB_ROOT_DIR)/grub_make_bios/build.sh $(GRUB_ROOT_DIR)/grub_make_bios/early_grub.cfg
	cat $(GRUB_ROOT_DIR)/grub_template_bios.cfg | grep -v '#' | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g" > $(GRUB_ROOT_DIR)/grub_make_bios/grub.cfg
	#cat $(GRUB_ROOT_DIR)/grub_template_menu.cfg | grep -v '#' | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g" >> $(GRUB_ROOT_DIR)/grub_make_bios/grub.cfg
	#cat $(GRUB_ROOT_DIR)/grub_template_menu.cfg | grep -v '#' | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g" > $(GRUB_ROOT_DIR)/grub_make_bios/grub_menu.cfg
	cd $(GRUB_ROOT_DIR)/grub_make_bios && ./build.sh

$(GRUB_ROOT_DIR)/grub.efi: $(GRUB_ROOT_DIR)/grub.cfg $(GRUB_ROOT_DIR)/grub_template_efi.cfg $(GRUB_ROOT_DIR)/grub_make_efi/build.sh
	cat $(GRUB_ROOT_DIR)/grub_template_efi.cfg  | grep -v '#' | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g"  > $(GRUB_ROOT_DIR)/grub_make_efi/grub.cfg
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

grub_menu: grub ipxe $(GRUB_ROOT_DIR)/.build_docker_image
	#cp $(readlink -f /root/docker/pxe-manager/tftp/vmlinuz) $(GRUB_ROOT_DIR)/grub_make_bios/vmlinuz
	#cp $(readlink -f /root/docker/pxe-manager/tftp/initrd)  $(GRUB_ROOT_DIR)/grub_make_bios/initrd
	docker run \
		--rm \
		--privileged=true \
		-v $(GRUB_ROOT_DIR)/:$(GRUB_ROOT_DIR)/ \
		$(DOCKERIMAGE) \
		/bin/bash -c 'cd $(GRUB_ROOT_DIR)/ && make UID=$(UID) GID=$(GID) docker_build_grub_menu'

# this is the actual build entry running inside docker
docker_build_grub_menu: $(GRUB_ROOT_DIR)/grub.efi $(GRUB_ROOT_DIR)/grub.booti386
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
		mkdir -p grub &&\
		git clone --recursive --depth=1 https://git.savannah.gnu.org/git/grub.git  $(GRUB_ROOT_DIR)/grub/git &&\
		cd $(GRUB_ROOT_DIR)/grub/git ;\
		git fetch --tags &&\
		lastest_tag=$$(git describe --tags $$(git rev-list --tags --max-count=1)) &&\
		echo $$lastest_tag &&\
		git checkout tags/$$lastest_tag -b $$lastest_tag ;\
	fi

$(GRUB_ROOT_DIR)/grub/git/configure: $(GRUB_ROOT_DIR)/grub/git
	cd $(GRUB_ROOT_DIR)/grub/git &&\
	if [ ! -e $(GRUB_ROOT_DIR)/grub/git/configure ] ; then ./bootstrap ; fi

$(GRUB_ROOT_DIR)/grub/git-install-efi-i386/bin/grub-mkimage: $(GRUB_ROOT_DIR)/grub/git/configure
	cd $(GRUB_ROOT_DIR)/grub/git &&\
	make clean ;\
	./configure --with-platform=efi --target=i386 --disable-werror --prefix=$(GRUB_ROOT_DIR)/grub/git-install-efi-i386 && \
	make -j $(CORE) ; make -j $(CORE) install

$(GRUB_ROOT_DIR)/grub/git-install-efi-x86_64/bin/grub-mkimage: $(GRUB_ROOT_DIR)/grub/git/configure
	cd $(GRUB_ROOT_DIR)/grub/git &&\
	make clean ;\
	./configure --with-platform=efi --target=x86_64 --disable-werror --prefix=$(GRUB_ROOT_DIR)/grub/git-install-efi-x86_64 &&\
	make -j $(CORE) ; make -j $(CORE) install

$(GRUB_ROOT_DIR)/grub/git-install-pc-i386/bin/grub-mkimage: $(GRUB_ROOT_DIR)/grub/git/configure
	cd $(GRUB_ROOT_DIR)/grub/git &&\
	make clean ;\
	./configure --with-platform=pc  --target=i386   --disable-werror --prefix=$(GRUB_ROOT_DIR)/grub/git-install-pc-i386    &&\
	make -j $(CORE) ; make -j $(CORE) install

$(GRUB_ROOT_DIR)/grub/git-install-pc-x86_64/bin/grub-mkimage: $(GRUB_ROOT_DIR)/grub/git/configure
	cd $(GRUB_ROOT_DIR)/grub/git &&\
	make clean ;\
	./configure --with-platform=pc  --target=x86_64 --disable-werror --prefix=$(GRUB_ROOT_DIR)/grub/git-install-pc-x86_64  &&\
	make -j $(CORE) ; make -j $(CORE) install


# =========================================================================================================================================================
# build ipxe from git
# =========================================================================================================================================================
ipxe: $(GRUB_ROOT_DIR)/ipxe.booti386

$(GRUB_ROOT_DIR)/ipxe.booti386: $(GRUB_ROOT_DIR)/.build_docker_image $(GRUB_ROOT_DIR)/Makefile
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
MENU_DEFAULT:=1
$(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe: docker_build_ipxe_git
	rm -rf $(GRUB_ROOT_DIR)/ipxe/git/src/menu
	echo "#!ipxe\n" > $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe
	echo "\n:retry_dhcp\ndhcp -t 3600 || goto retry_dhcp\n" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe
	grub=$$(egrep -v '#|echo' $(GRUB_ROOT_DIR)/grub_template_menu.cfg) ; \
	for n in $$(echo "$$grub" | grep menuentry | awk -F"'" '{print $$2}' | sed 's/ /./g') ; do \
		kernel=$$(echo "$$grub" | grep "$$n" -A5 | grep linux  | awk -F'linux ' '{print $$2}' | sed 's/PXE_TFTP/$(PXE_TFTP)/g') ; \
		initrd=$$(echo "$$grub" | grep "$$n" -A5 | grep initrd | awk -F'initrd ' '{print $$2}' | sed 's/PXE_TFTP/$(PXE_TFTP)/g') ; \
		if [ "$$(echo $$n | grep -i windows)" != "" ] ; then \
			echo "$$n@@" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu ; \
		fi ; \
		if [ "$$kernel" != "" ] ; then \
			echo "$$n@$$kernel@$$initrd" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu ; \
		fi ; \
	done
	echo ":start" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe  ; \
	echo 'menu iPXE boot menu ($${net0/ip})\nitem --gap --' >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe  ; \
	cat $(GRUB_ROOT_DIR)/ipxe/git/src/menu | while read m ; do \
		item=$$(echo "$$m" | awk -F'@' '{print $$1}') ; \
		echo "item $$item\t$$item" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe ; \
	done
	timeout=$$(grep timeout $(GRUB_ROOT_DIR)/grub_template_menu.cfg | grep -v '#' | awk -F'=' '{print $$2}') ; \
	t=$$(( $$timeout * 1000 )) ; \
	default=$(MENU_DEFAULT) ; \
	echo "choose --timeout $$t --default $$(head -n $$(( 0 + 1+ $$default ))  $(GRUB_ROOT_DIR)/ipxe/git/src/menu | tail -1 | awk -F'@' '{print $$1}') selected" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe
	echo 'set menu-timeout 0' >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe
	echo 'goto $${selected}\n' >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe
	cat $(GRUB_ROOT_DIR)/ipxe/git/src/menu | while read m ; do \
		item=$$(echo "$$m" | awk -F'@' '{print $$1}') ; \
		k=$$(echo "$$m" | awk -F'@' '{print $$2}' | awk '{print $$1}') ; \
		i=$$(echo "$$m" | awk -F'@' '{print $$3}') ; \
		a=$$(echo "$$m" | awk -F'@' '{print $$2}' | awk -F"$$k " '{print $$2}') ; \
		if [ "$$(echo $$item | grep -i windows)" != "" ] ; then \
			echo ":$$item\ngoto exit_ipxe\n" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe ; \
		else \
			echo ":$$item" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe ; \
			echo 'echo IP address: $${net0/ip} ; echo Subnet mask: $${net0/netmask} ;echo ' >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe ; \
			echo "kernel tftp://$(PXE_TFTP)/$$k || shell" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe ; \
			echo "initrd tftp://$(PXE_TFTP)/$$i" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe ; \
			echo "imgargs $$(basename $$k) $$a\nboot || sleep 600\ngoto start\n" >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe ; \
		fi ; \
	done
	echo ':exit_ipxe\n\n' >> $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe

# this is the actual build entry running inside docker
#DEBUG_EFI:=" DEBUG=efi_image "
ipxe_chainload_filename:=grub-netboot-git/grub.booti386
docker_build_ipxe: $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe
	gcc --version
	echo    "#!ipxe\
		\n:retry_dhcp\
		\ndhcp || goto retry_dhcp\
		\n\
		\necho Booting from $(ipxe_chainload_filename)\
		\necho IP address: ${net0/ip} ; echo Subnet mask: ${net0/netmask} \
		\n#chain tftp://$(PXE_TFTP)/$(ipxe_chainload_filename)\
		\nkernel tftp://$(PXE_TFTP)/vmlinuz\
		\ninitrd tftp://$(PXE_TFTP)/initrd\
		\nimgargs vmlinuz quiet nb_provisionurl=tftp://$(PXE_TFTP)/netbootcd-ipxe-bootchain/boot/init.sh  nofstab waitusb norestore base\
		\n#boot\
		\nexit\
	" > $(GRUB_ROOT_DIR)/ipxe/git/src/demo.ipxe
	cp $(GRUB_ROOT_DIR)/ipxe/git/src/menu.ipxe $(GRUB_ROOT_DIR)/ipxe/git/src/demo.ipxe
	cd $(GRUB_ROOT_DIR)/ipxe/git/src &&\
	make clean &&\
	LANG=C make NO_WERROR=1 -j $(CORE) bin-x86_64-efi/ipxe.efi EMBED=$(GRUB_ROOT_DIR)/ipxe/git/src/demo.ipxe $(DEBUG_EFI) &&\
	cp $(GRUB_ROOT_DIR)/ipxe/git/src/bin-x86_64-efi/ipxe.efi $(GRUB_ROOT_DIR)/ipxe.efi && \
	make clean &&\
	LANG=C make NO_WERROR=1 -j $(CORE) bin/undionly.kpxe EMBED=$(GRUB_ROOT_DIR)/ipxe/git/src/demo.ipxe &&\
	cp $(GRUB_ROOT_DIR)/ipxe/git/src/bin/undionly.kpxe $(GRUB_ROOT_DIR)/ipxe.booti386



