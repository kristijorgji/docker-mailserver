#!/usr/bin/env bash
#
# Apply configuration inside the running ms container.
#
# Runs Ansible playbook tags for DB, Postfix, Dovecot, OpenDKIM, optional
# spam filters, postfwd, and service reload.
# Usage: ./update.sh
#
# Uses WORKDIR /docker-data inside the image (cd ansible). Live-mount resolution
# for /dev-docker-data belongs in entrypoint.sh only — not here.
#
set -euo pipefail

if command -v docker-compose >/dev/null 2>&1; then
  COMPOSE=(docker-compose)
elif docker compose version >/dev/null 2>&1; then
  COMPOSE=(docker compose)
else
  echo "ERROR: neither docker-compose nor docker compose is available" >&2
  exit 1
fi

"${COMPOSE[@]}" exec -T ms bash -c \
  "service mysql start && cd ansible && ansible-playbook playbook.yml \
    --tags='db-provision,postfix-provision,dovecot-provision,opendkim-provision,rspamd-provision,postgrey-provision,postfwd-provision,reload'"
