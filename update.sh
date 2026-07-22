#!/usr/bin/env bash
#
# Apply configuration inside the running ms container.
#
# Runs Ansible playbook tags for DB, Postfix, Dovecot, OpenDKIM, optional
# spam filters, postfwd, and service reload.
# Usage: ./update.sh
#
set -euo pipefail

docker-compose exec -T ms bash -c \
  "service mysql start && cd ansible && ansible-playbook playbook.yml \
    --tags='db-provision,postfix-provision,dovecot-provision,opendkim-provision,rspamd-provision,postgrey-provision,postfwd-provision,reload'"
