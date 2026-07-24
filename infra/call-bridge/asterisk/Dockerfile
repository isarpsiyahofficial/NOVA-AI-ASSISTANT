FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        asterisk \
        asterisk-modules \
        curl \
        gettext-base \
        procps \
        sox \
    && rm -rf /var/lib/apt/lists/*

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
    && chmod -R 0777 /shared

EXPOSE 5060/udp 5060/tcp 5038/tcp 10000-10100/udp

HEALTHCHECK --interval=5s --timeout=4s --retries=20 CMD asterisk -rx "core show uptime" >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/opt/nova/entrypoint.sh"]
