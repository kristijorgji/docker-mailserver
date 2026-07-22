#!/usr/bin/env bash
set -euo pipefail

echo "==> Checking outbound rate limits (postfwd + anvil)"
docker compose exec -T ms grep -q 'check_policy_service inet:127.0.0.1:10040' /etc/postfix/master.cf
docker compose exec -T ms grep -q 'smtpd_client_message_rate_limit' /etc/postfix/master.cf
docker compose exec -T ms bash -c 'pgrep -x postfwd-server >/dev/null || pgrep -f "[p]ostfwd.*postfwd.cf" >/dev/null'

echo "Rate limit tests passed."
