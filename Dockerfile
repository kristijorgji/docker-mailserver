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
        logrotate \
    && python3 -m pip install --no-cache-dir PyMySQL \
    && cp /etc/cron.daily/logrotate /etc/cron.hourly/logrotate \
    && chmod 0755 /etc/cron.hourly/logrotate \
    && rm -f /etc/logrotate.d/dovecot /etc/logrotate.d/dovecot-core \
    && rm -rf /var/lib/apt/lists/*

ADD docker-data /docker-data
COPY docker-data/logrotate/syslog-ng /etc/logrotate.d/syslog-ng
COPY docker-data/mysql/zz-mailserver-low-memory.cnf /etc/mysql/mysql.conf.d/zz-mailserver-low-memory.cnf
WORKDIR /docker-data

ENTRYPOINT ["/usr/bin/tini", "--", "/docker-data/entrypoint.sh"]
