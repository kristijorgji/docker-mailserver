#!/usr/bin/env bash
set -euo pipefail

echo "==> Disabled rspamd and postgrey stay stopped"
docker compose exec -T ms bash -c '! pgrep -x rspamd'
docker compose exec -T ms bash -c '! pgrep -x postgrey'

echo "==> MySQL performance_schema is off"
schema=$(docker compose exec -T ms mysql --defaults-file=/root/.my.cnf -NBe 'select @@performance_schema' | tr -d '[:space:]')
test "$schema" = "0"

echo "==> logrotate config has no duplicate entries"
if docker compose exec -T ms logrotate -d /etc/logrotate.conf 2>&1 | grep -Eiq 'duplicate|^error:'; then
  echo "logrotate debug reported a duplicate or error" >&2
  docker compose exec -T ms logrotate -d /etc/logrotate.conf >&2 || true
  exit 1
fi

echo "==> logrotate rotates mail.log and new lines still arrive"
docker compose exec -T ms logrotate -f /etc/logrotate.conf
docker compose exec -T ms test -f /var/log/mail.log.1
if command -v swaks >/dev/null 2>&1; then
  swaks --to me@example.com --from test@example.com --server localhost --port 25 \
    --header "Subject: logrotate marker" --body "after-rotate" >/dev/null || true
else
  docker compose exec -T ms logger -p mail.info "after-rotate-marker"
fi
sleep 2
docker compose exec -T ms test -s /var/log/mail.log

echo "Image fix checks passed."
