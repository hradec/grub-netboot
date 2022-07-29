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
