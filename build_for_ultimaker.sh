#!/bin/bash

set -eu

ARCH="${ARCH:-armhf}"
SRC_DIR="$(pwd)"
BUILD_DIR="${SRC_DIR}/_build"
DEB_DIR="${BUILD_DIR}/_install"
PACKAGE_NAME="${PACKAGE_NAME:-connman}"
SYSCONFDIR="${SYSCONFDIR:-/etc}"
MODULES_LOAD_DIR="${SYSCONFDIR}/modules-load.d"

if [ -z "${RELEASE_VERSION+x}" ]; then
	RELEASE_VERSION="9999.99.99"
fi

./bootstrap

# Start with a clean build
if [ -d "${BUILD_DIR}" ] && [ -z "${BUILD_DIR##*_build*}" ]; then
    rm -rf "${BUILD_DIR}"
fi

mkdir "${BUILD_DIR}"
cd "${BUILD_DIR}"

CFLAGS=--sysroot="${SYSROOT}" LDFLAGS=--sysroot="${SYSROOT}" PKG_CONFIG="${SYSROOT}/../arm-pkg-config ${SYSROOT}" \
    ../configure --with-systemdunitdir=/lib/systemd/system --enable-polkit --prefix=/usr --localstatedir=/var \
	--build="$(gcc -dumpmachine)" --host=arm-linux-gnueabihf --with-sysroot="${SYSROOT}" --with-libtool-sysroot="${SYSROOT}"

make
make install DESTDIR="${DEB_DIR}"

mkdir "${DEB_DIR}/DEBIAN"

sed -e 's|@ARCH@|'"${ARCH}"'|g' \
        -e 's|@PACKAGE_NAME@|'"${PACKAGE_NAME}"'|g' \
        -e 's|@RELEASE_VERSION@|'"${RELEASE_VERSION}"'|g' \
        "${SRC_DIR}/debian/control.in" > "${DEB_DIR}/DEBIAN/control"

cp "${SRC_DIR}/debian/postinst" "${DEB_DIR}/DEBIAN/postinst"

mkdir -p "${DEB_DIR}/${MODULES_LOAD_DIR}"
cp "${SRC_DIR}/config/modules-load.d/connman.conf" "${DEB_DIR}/${MODULES_LOAD_DIR}/"

fakeroot dpkg-deb --build "${DEB_DIR}" ../connman-${RELEASE_VERSION}_armhf.deb
