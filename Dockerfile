FROM ghcr.io/sdr-enthusiasts/docker-baseimage:acars-decoder-soapy

ENV DEVICE_INDEX="" \
    QUIET_LOGS="TRUE" \
    FREQUENCIES="" \
    FEED_ID="" \
    PPM="0"\
    GAIN="40" \
    SERIAL="" \
    SOAPYSDR="" \
    SERVER="acarshub" \
    SERVER_PORT="5555" \
    VDLM_FILTER_ENABLE="TRUE" \
    VDLM_FILTER="all,-avlc_s,-acars_nodata,-x25_control,-idrp_keepalive,-esis" \
    STATSD_SERVER=""

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
COPY ./rootfs /
COPY ./bin/acars-bridge.arm64/acars-bridge /opt/acars-bridge.arm64
COPY ./bin/acars-bridge.amd64/acars-bridge /opt/acars-bridge.amd64

# hadolint ignore=DL3008,SC2086,SC2039
RUN set -x && \
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # Required for building multiple packages.
    TEMP_PACKAGES+=(build-essential) && \
    TEMP_PACKAGES+=(pkg-config) && \
    TEMP_PACKAGES+=(cmake) && \
    TEMP_PACKAGES+=(git) && \
    TEMP_PACKAGES+=(automake) && \
    TEMP_PACKAGES+=(autoconf) && \
    TEMP_PACKAGES+=(wget) && \
    # packages for dumpvdl2
    TEMP_PACKAGES+=(libglib2.0-dev) && \
    KEPT_PACKAGES+=(libglib2.0-0) && \
    TEMP_PACKAGES+=(libzmq3-dev) && \
    KEPT_PACKAGES+=(libzmq5) && \
    TEMP_PACKAGES+=(libusb-1.0-0-dev) && \
    KEPT_PACKAGES+=(libusb-1.0-0) && \
    # install packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
    "${KEPT_PACKAGES[@]}" \
    "${TEMP_PACKAGES[@]}"\
    && \
    # ensure binaries are executable
    chmod -v a+x \
    /opt/acars-bridge.arm64 \
    /opt/acars-bridge.amd64 \
    && \
    # remove foreign architecture binaries
    /rename_current_arch_binary.sh && \
    rm -fv \
    /opt/acars-bridge.* \
    && \
    # Install statsd-c-client library
    git clone https://github.com/romanbsd/statsd-c-client.git /src/statsd-client && \
    pushd /src/statsd-client && \
    make -j "$(nproc)" && \
    make install && \
    ldconfig && \
    popd && \
    # Install dumpvdl2
    git clone https://github.com/szpajder/dumpvdl2.git /src/dumpvdl2 && \
    mkdir -p /src/dumpvdl2/build && \
    pushd /src/dumpvdl2/build && \
    # cmake ../ && \
    cmake ../ -DCMAKE_BUILD_TYPE=RelWithDebInfo -DRTLSDR=FALSE && \
    make -j "$(nproc)" && \
    make install && \
    popd && \
    # Clean up
    apt-get remove -y "${TEMP_PACKAGES[@]}" && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/*

# Add healthcheck
HEALTHCHECK --start-period=3600s --interval=600s CMD /scripts/healthcheck.sh
