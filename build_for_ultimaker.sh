#!/bin/sh
# Copyright (C) 2019 Ultimaker B.V.
#

set -eu

LOCAL_REGISTRY_IMAGE="connman"

ARCH="${ARCH:-"arm64"}"
SRC_DIR="$(pwd)"
RELEASE_VERSION="${RELEASE_VERSION:-}"
DOCKER_WORK_DIR="/build"
BUILD_DIR_TEMPLATE="_build"
BUILD_DIR="${BUILD_DIR_TEMPLATE}"

update_docker_image()
{
    echo "Building local Docker build environment."
    docker build ./docker_env -t "${LOCAL_REGISTRY_IMAGE}"
}

run_in_docker()
{
    docker run \
        --privileged \
        --rm \
        -it \
        -u "$(id -u)" \
        -e "BUILD_DIR=${DOCKER_WORK_DIR}/${BUILD_DIR}" \
        -e "ARCH=${ARCH}" \
        -e "RELEASE_VERSION=${RELEASE_VERSION}" \
        -e "MAKEFLAGS=-j$(($(getconf _NPROCESSORS_ONLN) - 1))" \
        -v "${SRC_DIR}:${DOCKER_WORK_DIR}" \
        -w "${DOCKER_WORK_DIR}" \
        "${LOCAL_REGISTRY_IMAGE}" \
        "${@}"
}

run_build()
{
    run_in_docker "./build.sh" "${@}"
}

deliver_pkg()
{
    cp "${BUILD_DIR}/"*".deb" "./"
}

run_tests()
{
    echo "There are no tests available for this repository."
}

usage()
{
    echo "Usage: ${0} [OPTIONS]"
    echo "  -c   Clean the workspace"
    echo "  -h   Print usage"
    echo
    echo "Other options will be passed on to build.sh"
    echo "Run './build.sh -h' for more information."
}

while getopts ":cChlt" options; do
    case "${options}" in
    c)
        run_build "${@}"
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

if ! command -V docker; then
    echo "Docker not found, docker-less builds are not supported."
    exit 1
fi

update_docker_image

run_build "${@}"

deliver_pkg

exit 0
