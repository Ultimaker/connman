#!/bin/bash
# shellcheck disable=SC1117

set -eux

ARCH="arm64"
UM_ARCH="imx8m" # Empty string, or sun7i for R1, or imx6dl for R2, or imx8m for colorado

# common directory variablesS
SRC_DIR="$(pwd)"
BUILD_DIR_TEMPLATE="_build"
BUILD_DIR="${BUILD_DIR:-${SRC_DIR}/${BUILD_DIR_TEMPLATE}}"

# Debian package information
PACKAGE_NAME="${PACKAGE_NAME:-"connman"}"
RELEASE_VERSION="${RELEASE_VERSION:-"999.999.999"}"
MODULES_LOAD_DIR="/etc/modules-load.d"

DEBIAN_DIR="${BUILD_DIR}/debian"


build()
{
    #./bootstrap
    autoreconf -vfi
    # Start with a clean build
    if [ -d "${BUILD_DIR}" ] && [ -z "${BUILD_DIR##*_build*}" ]; then
        rm -rf "${BUILD_DIR}"
    fi
    
    mkdir -p "${BUILD_DIR}"
    cd "${BUILD_DIR}"
    
    ../configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --with-systemdunitdir=/lib/systemd/system --enable-polkit
    make
    make install DESTDIR="${DEBIAN_DIR}"
    
    echo "Finished building."
}


create_debian_package()
{
    echo "Building Debian package."

    mkdir -p "${DEBIAN_DIR}/DEBIAN"
    sed -e 's|@ARCH@|'"${ARCH}"'|g' \
        -e 's|@PACKAGE_NAME@|'"${PACKAGE_NAME}"'|g' \
        -e 's|@RELEASE_VERSION@|'"${RELEASE_VERSION}-${UM_ARCH}"'|g' \
        "${SRC_DIR}/debian/control.in" > "${DEBIAN_DIR}/DEBIAN/control"

   
    cp "${SRC_DIR}/debian/postinst" "${DEBIAN_DIR}/DEBIAN/postinst"

    mkdir -p "${DEBIAN_DIR}/${MODULES_LOAD_DIR}"
    cp "${SRC_DIR}/config/modules-load.d/connman.conf" "${DEBIAN_DIR}/${MODULES_LOAD_DIR}/"

    DEB_PACKAGE="${PACKAGE_NAME}_${RELEASE_VERSION}-${UM_ARCH}_${ARCH}.deb"

    # Build the Debian package
    fakeroot dpkg-deb --build "${DEBIAN_DIR}" "${BUILD_DIR}/${DEB_PACKAGE}"

    echo "Finished building Debian package."
    echo "To check the contents of the Debian package run 'dpkg-deb -c *.deb'"
}

usage()
{
    echo ""
    echo "This is the build script for Connman connection manager."
    echo ""
    echo "  -c Clean the build output directory '_build'."
    echo "  -h Print this help text and exit"
    echo ""
    echo "  The package release version can be passed by passing 'RELEASE_VERSION' through the run environment."
}

pwd

while getopts ":ch" options; do
    case "${options}" in
    c)
        if [ -d "${BUILD_DIR}" ] && [ -z "${BUILD_DIR##*_build*}" ]; then
            rm -rf "${BUILD_DIR}"
        fi
        exit 0
        ;;
    h)
        usage
        exit 0
        ;;
    :)
        echo "Option -${OPTARG} requires an argument."
        exit 1
        ;;
    ?)
        echo "Invalid option: -${OPTARG}"
        exit 1
        ;;
    esac
done
shift "$((OPTIND - 1))"


if [ "${#}" -gt 1 ]; then
    echo "Too many arguments."
    usage
    exit 1
fi

if [ "${#}" -eq 0 ]; then
    build
    create_debian_package
    exit 0
fi

case "${1-}" in
    deb)
        build
        create_debian_package
        ;;
    *)
        echo "Error, unknown build option given"
        usage
        exit 1
        ;;
esac

exit 0
