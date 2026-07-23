#!/usr/bin/env bash
set -euo pipefail

# Configure mail linux user
# TODO move this into the ansible provisioning so user and group names come from variables
groupadd -g 5000 vmail 2>/dev/null || true
id -u vmail &>/dev/null || useradd -s /usr/sbin/nologin -u 5000 -g 5000 vmail
usermod -aG vmail postfix 2>/dev/null || true
usermod -aG vmail dovecot 2>/dev/null || true

mkdir -p /var/mail/vhosts \
    && chown -R vmail:vmail /var/mail/vhosts \
    && chmod -R 750 /var/mail/vhosts

# Boot: schema + service configs only (no vault user sync).
# Run ./update.sh on the host for db-provision (mail_accounts / mail_domains).
DOCKER_DATA_ROOT=/dev-docker-data
if [ ! -d "$DOCKER_DATA_ROOT/ansible" ]; then
  DOCKER_DATA_ROOT=/docker-data
fi

# Never run --initialize against a non-empty datadir (would wipe production).
# A missing mysql/ schema with leftover InnoDB files means the volume is corrupt —
# fail loudly instead of re-initializing.
if [ ! -d /var/lib/mysql/mysql ]; then
  if [ -n "$(ls -A /var/lib/mysql 2>/dev/null)" ]; then
    echo "ERROR: /var/lib/mysql is non-empty but missing the mysql system schema." >&2
    echo "Refusing to run mysqld --initialize (would destroy existing files)." >&2
    echo "Restore from backup, or move the broken datadir aside and recreate." >&2
    exit 1
  fi
  mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql
fi

service mysql start
for i in $(seq 1 30); do
    if [ -S /var/run/mysqld/mysqld.sock ]; then
        break
    fi
    sleep 2
done

cd "$DOCKER_DATA_ROOT/ansible"
ansible-playbook playbook.yml \
    --tags certificates,schema-init,postfix-provision,dovecot-provision,opendkim-provision,rspamd-provision,postgrey-provision,postfwd-provision
cd -

# start up all necessary services
service syslog-ng start
service cron start 2>/dev/null || true
service opendkim start 2>/dev/null || true
service rspamd start 2>/dev/null || true
service postgrey start 2>/dev/null || true
service postfwd start 2>/dev/null || true
service postfix start
service dovecot start

# keep container up and running as we don't start any server
exec tail -f /var/log/mail.log /var/log/mail.err /var/log/syslog 2>/dev/null || tail -f /var/log/*
