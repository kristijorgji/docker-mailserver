#!/usr/bin/env bash
set -euo pipefail

echo "==> Checking Rspamd milter in Postfix"
docker compose exec -T ms grep -q 'inet:localhost:11332' /etc/postfix/main.cf

echo "==> Checking Rspamd service is running"
docker compose exec -T ms service rspamd status

echo "==> Checking Rspamd milter headers config"
docker compose exec -T ms test -f /etc/rspamd/local.d/milter_headers.conf

echo "Rspamd render tests passed."
