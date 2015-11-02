#!/bin/bash

set -u
set -e

./bootstrap
mkdir _build
cd _build
CFLAGS=--sysroot=${SYSROOT} LDFLAGS=--sysroot=${SYSROOT} PKG_CONFIG="${SYSROOT}/../arm-pkg-config ${SYSROOT}" ../configure --with-systemdunitdir=/lib/systemd/system --enable-polkit \
	--build=`gcc -dumpmachine` --host=arm-linux-gnueabihf --with-sysroot=${SYSROOT} --with-libtool-sysroot=${SYSROOT}

make
make install DESTDIR=`pwd`/_install

