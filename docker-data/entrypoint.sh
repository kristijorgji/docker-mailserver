#!/usr/bin/env bash

# Configure mail linux user
# TODO move this into the ansible provisioning so user and group names come from variables
groupadd -g 5000 vmail  \
    && useradd -s /usr/sbin/nologin -u 5000 -g 5000 vmail \
    && usermod -aG vmail postfix \
    && usermod -aG vmail dovecot

# apply ansible configs
cd ansible
ansible-playbook playbook.yml
cd -

# start up all necessary services
service syslog-ng start
service postfix start
service dovecot start;

# keep container up and running as we don't start any server
tail -f /var/log/*
