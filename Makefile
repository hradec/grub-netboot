
PXE_TEMP_IP:=192.168.1.250
PXE_TFTP:=192.168.1.231

GRUB_ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
CORES:=$(shell nproc)

# we use uid and gid to keep files with the correct permissions, since docker
# runs as root user!
UID=$(shell id -u)
GID=$(shell id -g)

# by default, run this makefile in the docker build environment
all: build_docker_image_and_run

# this is the actual build entry running inside docker
docker_build: $(GRUB_ROOT_DIR)/grub.efi

$(GRUB_ROOT_DIR)/grub.efi: $(GRUB_ROOT_DIR)/grub_template_menu.cfg $(GRUB_ROOT_DIR)/grub_template_bios.cfg $(GRUB_ROOT_DIR)/grub_template_efi.cfg $(GRUB_ROOT_DIR)/grub_make_bios/build.sh $(GRUB_ROOT_DIR)/grub_make_efi/build.sh
	cat $(GRUB_ROOT_DIR)/grub_template_menu.cfg | grep -v '#' | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g" > $(GRUB_ROOT_DIR)/grub.cfg && \
	cat $(GRUB_ROOT_DIR)/grub_template_menu.cfg | grep -v '#' | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g" > $(GRUB_ROOT_DIR)/grub_make_bios/grub_menu.cfg && \
	cat $(GRUB_ROOT_DIR)/grub_template_bios.cfg | grep -v '#' | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g" > $(GRUB_ROOT_DIR)/grub_make_bios/grub.cfg && \
	cat $(GRUB_ROOT_DIR)/grub_template_menu.cfg | grep -v '#' | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g" >> $(GRUB_ROOT_DIR)/grub_make_bios/grub.cfg && \
	cd $(GRUB_ROOT_DIR)/grub_make_bios && ./build.sh && cd .. && \
	cat $(GRUB_ROOT_DIR)/grub_template_efi.cfg | grep -v '#' | sed "s/PXE_TEMP_IP/${PXE_TEMP_IP}/g" | sed "s/PXE_TFTP/${PXE_TFTP}/g"  > $(GRUB_ROOT_DIR)/grub_make_efi/grub.cfg && \
	cd $(GRUB_ROOT_DIR)/grub_make_efi && ./build.sh && cd .. && \
	mkdir -p $(GRUB_ROOT_DIR)/./OSX/grub.nbi/i386 && sudo cp -rf $(GRUB_ROOT_DIR)/grub.* $(GRUB_ROOT_DIR)/./OSX/grub.nbi/i386 && \
	chown -R $(UID):$(GID) $(GRUB_ROOT_DIR)/grub.*  ;\
	chown -R $(UID):$(GID) $(GRUB_ROOT_DIR)/grub_make_efi/grub.*  ;\
	chown -R $(UID):$(GID) $(GRUB_ROOT_DIR)/grub_make_bios/grub.*  ;\
	chown -R $(UID):$(GID) $(GRUB_ROOT_DIR)/OSX/  ;\

build_docker_image:
	cd $(GRUB_ROOT_DIR)/docker/ &&\
	docker build . -t grub-netboot-build

build_docker_image_and_run: build_docker_image
	docker run \
		--rm \
		--privileged=true \
		-v $(GRUB_ROOT_DIR)/:$(GRUB_ROOT_DIR)/ \
		grub-netboot-build \
		/bin/bash -c 'cd $(GRUB_ROOT_DIR)/ && make UID=$(UID) GID=$(GID) docker_build'


clean:
	rm -f $(GRUB_ROOT_DIR)/grub.*
	rm -f $(GRUB_ROOT_DIR)/grub_make_efi/grub.*
	rm -f $(GRUB_ROOT_DIR)/grub_make_bios/grub.*
	rm -rf $(GRUB_ROOT_DIR)/OSX
	rm -f $(GRUB_ROOT_DIR)/.done
	rm -rf $(GRUB_ROOT_DIR)/git


.PHONY: grub
grub: build_docker_image
	docker run \
                --rm \
                --privileged=true \
                -v $(GRUB_ROOT_DIR)/:$(GRUB_ROOT_DIR)/ \
                grub-netboot-build \
                /bin/bash -c 'cd $(GRUB_ROOT_DIR)/ && make UID=$(UID) GID=$(GID) docker_build_grub'

docker_build_grub:
	if [ ! -e $(GRUB_ROOT_DIR)/grub/git ] ; then \
		mkdir -p grub &&\
		git clone --recursive --depth=1 https://git.savannah.gnu.org/git/grub.git  $(GRUB_ROOT_DIR)/grub/git &&\
		cd $(GRUB_ROOT_DIR)/grub/git ;\
		#git fetch --tags &&\
		#lastest_tag=$$(git describe --tags $$(git rev-list --tags --max-count=1)) &&\
		#echo $$lastest_tag &&\
		#git checkout tags/$$lastest_tag -b $$lastest_tag ;\
	fi
	cd $(GRUB_ROOT_DIR)/grub/git &&\
	if [ ! -e $(GRUB_ROOT_DIR)/grub/git/configure ] ; then ./bootstrap ; fi &&\
	make clean ;\
	./configure --with-platform=efi --target=i386 --disable-werror --prefix=$(GRUB_ROOT_DIR)/grub/git-install-efi-x86_64 &&\
	make -j $(CORE) ; make -j $(CORE) install &&\
	make clean &&\
	./configure --with-platform=efi --target=x86_64 --disable-werror --prefix=$(GRUB_ROOT_DIR)/grub/git-install-efi-x86_64 &&\
	make -j $(CORE) ; make -j $(CORE) install &&\
	make clean &&\
	./configure --with-platform=pc  --target=i386   --disable-werror --prefix=$(GRUB_ROOT_DIR)/grub/git-install-pc-i386    &&\
	make -j $(CORE) ; make -j $(CORE) install &&\
	make clean &&\
	./configure --with-platform=pc  --target=x86_64 --disable-werror --prefix=$(GRUB_ROOT_DIR)/grub/git-install-pc-x86_64  &&\
	make -j $(CORE) ; make -j $(CORE) install &&\
	make clean

