#!/usr/bin/env bash
set -euo pipefail

echo "==> Checking inbound rate limits (anvil on port 25 smtpd)"
docker compose exec -T ms bash -c \
  'grep -A6 "^smtpd.*pass" /etc/postfix/master.cf | grep -q smtpd_client_connection_count_limit'

echo "Inbound rate limit tests passed."
