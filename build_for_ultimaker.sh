#!/bin/bash

set -u
set -e

SRC_DIR="$(pwd)"
BUILD_DIR="${SRC_DIR}/_build"
DEB_DIR="${BUILD_DIR}/_install"
SYSCONFDIR="${SYSCONFDIR:-/etc}"
MODULES_LOAD_DIR="${SYSCONFDIR}/modules-load.d"

if [ -z ${RELEASE_VERSION+x} ]; then
	RELEASE_VERSION=9999.99.99
fi

./bootstrap
rm -rf _build
mkdir _build
cd _build
CFLAGS=--sysroot=${SYSROOT} LDFLAGS=--sysroot=${SYSROOT} PKG_CONFIG="${SYSROOT}/../arm-pkg-config ${SYSROOT}" ../configure --with-systemdunitdir=/lib/systemd/system --enable-polkit --prefix=/usr --localstatedir=/var \
	--build=`gcc -dumpmachine` --host=arm-linux-gnueabihf --with-sysroot=${SYSROOT} --with-libtool-sysroot=${SYSROOT}

make
make install DESTDIR=`pwd`/_install

mkdir _install/DEBIAN

cat > "_install/DEBIAN/control" <<-EOT
Package: connman
Source: connman
Version: ${RELEASE_VERSION}
Architecture: armhf
Maintainer: Anonymous <root@monolith.ultimaker.com>
Depends: libc6 (>= 2.15), libdbus-1-3 (>= 1.1.1), libglib2.0-0 (>= 2.28.0), libgnutls-deb0-28 (>= 3.3.0), libreadline6 (>= 6.0), libxtables10, init-system-helpers (>= 1.18~), dbus, lsb-base
Priority: optional
Description: Intel Connection Manager daemon
 The Linux Connection Manager project provides a daemon for managing
 Internet connections within embedded devices running the Linux
 operating system. The Connection Manager is designed to be slim and to
 use as few resources as possible. It is fully modular system that
 can be extended through plug-ins. The plug-in approach allows for
 easy adaption and modification for various use cases.
 .
 ConnMan provies IPv4 and IPv6 connectivity via:
  * ethernet
  * WiFi, using wpasupplicant
  * Cellular, using oFono
  * Bluetooth, using bluez
 .
 ConnMan implements DNS resolving and caching, DHCP clients for both IPv4 and
 IPv6, link-local IPv4 address handling and tethering (IP connection sharing)
 to clients via USB, ethernet, WiFi, cellular and Bluetooth.
 .
 This package contains the connman daemon and its plugins.
EOT

cat > "_install/DEBIAN/postinst" <<-EOT
#!/bin/sh

set -e

# This will only remove masks created by d-s-h on package removal.
deb-systemd-helper unmask connman.service >/dev/null || true

# was-enabled defaults to true, so new installations run enable.
if deb-systemd-helper --quiet was-enabled connman.service; then
        # Enables the unit on first installation, creates new
        # symlinks on upgrades if the unit file has changed.
        deb-systemd-helper enable connman.service >/dev/null || true
else
        # Update the statefile to add new symlinks (if any), which need to be
        # cleaned up on purge. Also remove old symlinks.
        deb-systemd-helper update-state connman.service >/dev/null || true
fi
EOT
chmod +x "_install/DEBIAN/postinst"

mkdir -p "${DEB_DIR}/${MODULES_LOAD_DIR}"
cp "${SRC_DIR}/config/modules-load.d/connman.conf" "${DEB_DIR}/${MODULES_LOAD_DIR}/"

fakeroot dpkg-deb --build "_install" ../connman-${RELEASE_VERSION}_armhf.deb
