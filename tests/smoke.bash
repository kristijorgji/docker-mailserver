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

echo "==> Checking submission port 587 is listening"
docker compose exec -T ms bash -c 'timeout 2 bash -c "cat < /dev/null > /dev/tcp/127.0.0.1/587"'

echo "All smoke tests passed."
