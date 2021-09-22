FROM arm32v7/debian:buster
#FROM balenalib/aarch64-debian:buster

LABEL Maintainer="software-embedded@ultimaker.com" \
      Comment="Ultimaker buster build environment"

RUN apt-get update && \
    apt-get install -y \
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
    libreadline6-dev \
    libtool \
    libxtables-dev \
    pkg-config \
    policykit-1 \
    && \
    apt-get clean && \
    rm -rf /var/cache/apt/*
