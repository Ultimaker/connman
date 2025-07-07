FROM registry.hub.docker.com/library/debian:bookworm-slim

LABEL Maintainer="software-embedded@ultimaker.com" \
      Comment="Ultimaker bookworm build environment"

# Install necessary packages for building connman on Bookworm.
# We're updating the apt cache and installing all build dependencies in one layer
# to optimize Docker caching.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    apt-utils \
    autoconf \
    automake \
    build-essential \
    bzip2 \
    cmake \
    fakeroot \
    git \
    gnutls-bin \
    g++ \
    iptables \
    libdbus-1-dev \
    libglib2.0-dev \
    libgnutls28-dev \
    libreadline-dev \
    libtool \
    libxtables-dev \
    pkg-config \
    policykit-1 \
    # Consider adding other common connman dependencies if needed for your specific build:
    # libbluetooth-dev # For Bluetooth support
    # libudev-dev      # For udev integration
    # libsystemd-dev   # For systemd integration (if using systemd's features)
    && \
    apt-get clean && \
    rm -rf /var/cache/apt/* /var/lib/apt/lists/*

# Add further steps here if your build process involves
# cloning specific repos, patching, configuring, compiling, etc.
# Example:
# COPY . /connman-source
# WORKDIR /connman-source
# RUN ./autogen.sh && \
#     ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var && \
#     make -j$(nproc) && \
#     make install DESTDIR=/build_output
#
# # You might then want to create a debian package or simply copy the binaries out