#!/usr/bin/env bash
set -euo pipefail

echo "==> Checking Dovecot quota plugin"
docker compose exec -T ms bash -c 'doveconf -n 2>/dev/null | grep -q quota'

echo "==> Checking quota_bytes column exists"
docker compose exec -T ms mysql --defaults-file=/root/.my.cnf -N -e \
  "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='mailserver' AND TABLE_NAME='virtual_users' AND COLUMN_NAME='quota_bytes'" \
  | grep -q '^1$'

echo "Quota tests passed."
