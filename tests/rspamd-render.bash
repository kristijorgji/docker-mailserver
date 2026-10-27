#!/usr/bin/env bash
set -euo pipefail

echo "==> Checking Rspamd milter in Postfix"
docker compose exec -T ms grep -q 'inet:localhost:11332' /etc/postfix/main.cf

echo "==> Rspamd and postgrey start when enabled"
docker compose exec -T ms service rspamd status
docker compose exec -T ms service postgrey status

echo "==> Checking Rspamd milter headers config"
docker compose exec -T ms test -f /etc/rspamd/local.d/milter_headers.conf

echo "==> SASL client modules are installed"
docker compose exec -T ms dpkg -s libsasl2-modules >/dev/null

echo "==> IMAP does not load the sieve delivery plugin"
docker compose exec -T ms grep -F 'mail_plugins = $mail_plugins imap_sieve' /etc/dovecot/conf.d/90-sieve.conf
docker compose exec -T ms bash -c '! grep -F "imap_sieve sieve" /etc/dovecot/conf.d/90-sieve.conf'

echo "==> Postfix policy restriction is one master.cf argument"
count=$(docker compose exec -T ms grep -F -c '{ smtpd_client_restrictions=permit_sasl_authenticated, check_policy_service inet:127.0.0.1:10040, reject }' /etc/postfix/master.cf | tr -d '[:space:]')
test "$count" -ge 2

echo "==> Spamhaus listings ignore the public-resolver code"
docker compose exec -T ms grep -F 'zen.spamhaus.org=127.0.0.[2..11]' /etc/postfix/main.cf

echo "Rspamd render tests passed."
