#!/usr/bin/env bash

PATH_SSL="/etc/letsencrypt/live/${MAIL_DOMAIN}"

# Configure mail linux user
groupadd -g 5000 vmail  \
    && useradd -s /usr/sbin/nologin -u 5000 -g 5000 vmail \
    && usermod -aG vmail postfix \
    && usermod -aG vmail dovecot

# Create mails directory with correct owner
mkdir -p /var/mail/vhosts/$DOMAIN \
    && chown -R vmail:vmail /var/mail/vhosts \
    && chmod -R 775 /var/mail/vhosts

# create dovecot ssl if not existing
./gen-certificate.sh "$DOMAIN" "$PATH_SSL"

# apply ansible configs
ansible-playbook ansible/playbook.yml

# start up all necessary services
service postfix start
service dovecot start;

# keep container up and running as we don't start any server
tail -f /dev/null
