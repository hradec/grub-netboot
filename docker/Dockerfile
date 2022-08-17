FROM debian:11

RUN apt update ;\
    apt install -y \
        zip \
        dosfstools \
        syslinux-utils \
        genisoimage \
        build-essential \
        wget

RUN apt install -y \
        squashfs-tools \
        cpio \
        curl \
        util-linux

RUN apt install -y \
        grub2 \
        sudo

RUN apt install -y \
        autoconf \
        automake \
	git

RUN apt install -y \
	autopoint \
	pkg-config \
	bison \
	flex

RUN apt install -y \
	python \
	libdevmapper-dev \
	libfreetype-dev \
	ipxe \
	extlinux \
	isolinux

RUN apt install -y \
	libfuse-dev \
	fonts-dejavu \
	fonts-dejavu-core \
	fonts-dejavu-extra

RUN apt install -y \
	lzma-dev \
	liblzma-dev

RUN dpkg --add-architecture i386 ;\
    apt update ;\
    apt install -y -o Acquire::Retries=50 \
	mtools syslinux isolinux \
	libc6-dev-i386 libc6-dbg:i386 valgrind
