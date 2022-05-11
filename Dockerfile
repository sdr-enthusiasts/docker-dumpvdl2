FROM ghcr.io/sdr-enthusiasts/docker-baseimage:acars-decoder

ENV DEVICE_INDEX="" \
    QUIET_LOGS="TRUE" \
    FREQUENCIES="" \
    FEED_ID="" \
    PPM="0"\
    GAIN="40" \
    SERIAL="" \
    SERVER="acarshub" \
    SERVER_PORT="5555" \
    VDLM_FILTER_ENABLE="TRUE"

# hadolint ignore=DL3008,SC2086,SC2039,SC3054
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
    # install packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
    "${KEPT_PACKAGES[@]}" \
    "${TEMP_PACKAGES[@]}"\
    && \
    git clone https://github.com/szpajder/dumpvdl2.git /src/dumpvdl2 && \
    mkdir -p /src/dumpvdl2/build && \
    pushd /src/dumpvdl2/build && \
    cmake ../ && \
    make -j "$(nproc)" && \
    make install && \
    popd && \
    # Clean up
    apt-get remove -y "${TEMP_PACKAGES[@]}" && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/*


COPY rootfs/ /

# ENTRYPOINT [ "/init" ]

# Add healthcheck
HEALTHCHECK --start-period=3600s --interval=600s CMD /scripts/healthcheck.sh
