FROM ubuntu:22.04@sha256:0e0a0fc6d18feda9db1590da249ac93e8d5abfea8f4c3c0c849ce512b5ef8982

USER root

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
        # init / orchestration
        tini \
        ansible \
        python3-pip \
        # mail stack
        postfix \
        postfix-mysql \
        mysql-server \
        dovecot-core \
        dovecot-pop3d \
        dovecot-imapd \
        dovecot-mysql \
        dovecot-common \
        dovecot-lmtpd \
        dovecot-sieve \
        # TLS
        certbot \
        # logging
        syslog-ng \
        # signing
        opendkim \
        opendkim-tools \
        # optional spam / rate limiting (enabled via vars.yml)
        rspamd \
        postgrey \
        postfwd \
        # housekeeping
        cron \
    && python3 -m pip install --no-cache-dir PyMySQL \
    && rm -rf /var/lib/apt/lists/*

ADD docker-data /docker-data
WORKDIR /docker-data

ENTRYPOINT ["/usr/bin/tini", "--", "/docker-data/entrypoint.sh"]
