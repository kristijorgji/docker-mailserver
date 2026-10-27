#!/usr/bin/env bash
set -euo pipefail

echo "==> Checking Postscreen/DNSBL configuration"
docker compose exec -T ms grep -q 'postscreen_dnsbl_sites' /etc/postfix/main.cf
docker compose exec -T ms grep -q 'zen.spamhaus.org' /etc/postfix/main.cf

echo "==> Checking OpenDKIM milter"
docker compose exec -T ms grep -q 'inet:localhost:8891' /etc/postfix/main.cf

echo "==> Checking Postfix configuration"
docker compose exec -T ms postfix check

bash "$(dirname "$0")/open-relay.bash"
bash "$(dirname "$0")/imap-auth.bash"
bash "$(dirname "$0")/rate-limits.bash"
bash "$(dirname "$0")/inbound-rate-limits.bash"
bash "$(dirname "$0")/quotas.bash"
bash "$(dirname "$0")/db-upsert.bash"

echo "==> Checking MySQL mail accounts exist"
count=$(docker compose exec -T ms bash -c "mysql --defaults-file=/root/.my.cnf -N -e 'SELECT COUNT(*) FROM mailserver.virtual_users'")
test "$count" -ge 1

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

echo "==> Checking submission port 587 is listening"
docker compose exec -T ms bash -c 'timeout 2 bash -c "cat < /dev/null > /dev/tcp/127.0.0.1/587"'

echo "All smoke tests passed."
