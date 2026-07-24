FROM debian:bookworm-slim

ARG ASTERISK_VERSION=22.10.1
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        file \
        gettext-base \
        libcurl4-openssl-dev \
        libedit-dev \
        libjansson-dev \
        libncurses-dev \
        libnewt-dev \
        libogg-dev \
        libopus-dev \
        libspeexdsp-dev \
        libsqlite3-dev \
        libsrtp2-dev \
        libssl-dev \
        libsystemd-dev \
        liburiparser-dev \
        libvorbis-dev \
        libxml2-dev \
        libxslt1-dev \
        pkg-config \
        procps \
        sox \
        uuid-dev \
        uuid-runtime \
        wget \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src
RUN curl --fail --location --retry 5 --retry-all-errors \
        "https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${ASTERISK_VERSION}.tar.gz" \
        -o "asterisk-${ASTERISK_VERSION}.tar.gz" \
    && curl --fail --location --retry 5 --retry-all-errors \
        "https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${ASTERISK_VERSION}.sha256" \
        -o "asterisk-${ASTERISK_VERSION}.sha256" \
    && expected="$(awk '{print $1}' "asterisk-${ASTERISK_VERSION}.sha256")" \
    && actual="$(sha256sum "asterisk-${ASTERISK_VERSION}.tar.gz" | awk '{print $1}')" \
    && test -n "$expected" \
    && test "$expected" = "$actual" \
    && tar -xzf "asterisk-${ASTERISK_VERSION}.tar.gz"

WORKDIR /usr/src/asterisk-${ASTERISK_VERSION}
RUN ./configure \
        --with-pjproject-bundled \
        --with-jansson-bundled \
        --without-dahdi \
        --without-pri \
        --without-ss7 \
    && make menuselect.makeopts \
    && menuselect/menuselect \
        --disable BUILD_NATIVE \
        --enable app_audiosocket \
        --enable res_audiosocket \
        --enable app_mixmonitor \
        --enable app_dial \
        --enable app_playback \
        --enable app_stack \
        --enable chan_pjsip \
        --enable res_pjsip \
        --enable res_pjsip_outbound_registration \
        --enable res_rtp_asterisk \
        --enable func_shell \
        --enable func_strings \
        --enable func_cdr \
        --enable format_wav \
        --enable codec_ulaw \
        menuselect.makeopts \
    && make -j"$(nproc)" \
    && make install \
    && make install-logrotate \
    && ldconfig \
    && asterisk -V \
    && test -s /usr/lib/asterisk/modules/app_audiosocket.so \
    && test -s /usr/lib/asterisk/modules/res_audiosocket.so

WORKDIR /
COPY config/asterisk.conf /etc/asterisk/asterisk.conf
COPY config/modules.conf /etc/asterisk/modules.conf
COPY config/extensions.conf /etc/asterisk/extensions.conf
COPY config/pjsip.conf /etc/asterisk/pjsip.conf
COPY config/logger.conf /etc/asterisk/logger.conf
COPY config/rtp.conf /etc/asterisk/rtp.conf
COPY config/pjsip.carrier.conf.template /opt/nova/pjsip.carrier.conf.template
COPY config/manager.conf /opt/nova/manager.conf.template
COPY entrypoint.sh /opt/nova/entrypoint.sh

RUN chmod +x /opt/nova/entrypoint.sh \
    && mkdir -p /shared/sounds /shared/recordings /shared/reports \
    && chmod -R 0777 /shared \
    && rm -rf /usr/src/asterisk-${ASTERISK_VERSION} /usr/src/asterisk-${ASTERISK_VERSION}.tar.gz

EXPOSE 5060/udp 5060/tcp 5038/tcp 10000-10100/udp

HEALTHCHECK --interval=5s --timeout=4s --retries=30 CMD asterisk -rx "core show uptime" >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/opt/nova/entrypoint.sh"]
