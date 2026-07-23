#!/usr/bin/env bash
set -euo pipefail

USER="${MAIL_TEST_USER:-me@example.com}"
PASS="${MAIL_TEST_PASS:-ci_account_password}"
BAD_PASS="${MAIL_TEST_BAD_PASS:-wrongpassword}"

echo "==> Checking IMAP auth accepts valid credentials"
docker compose exec -T ms doveadm auth test "$USER" "$PASS"

echo "==> Checking IMAP auth rejects invalid credentials"
set +e
docker compose exec -T ms doveadm auth test "$USER" "$BAD_PASS" >/dev/null 2>&1
rc=$?
set -e
if [ "$rc" -eq 0 ]; then
  echo "FAIL: invalid password was accepted"
  exit 1
fi
echo "Invalid credentials correctly rejected"

echo "==> Checking real IMAP LOGIN over TLS (993)"
# openssl s_client may exit non-zero on clean IMAP LOGOUT; capture output regardless.
set +e
imap_out="$(
  {
    printf 'a1 LOGIN %s %s\r\n' "$USER" "$PASS"
    printf 'a2 LOGOUT\r\n'
  } | docker compose exec -T ms timeout 20 openssl s_client -connect 127.0.0.1:993 -quiet -ign_eof 2>/dev/null
)"
imap_rc=$?
set -e

if ! printf '%s\n' "$imap_out" | grep -qE 'a1 OK'; then
  echo "FAIL: IMAP LOGIN over 993 did not return OK (openssl/imap rc=${imap_rc})"
  printf '%s\n' "$imap_out" | tail -n 40
  echo "==> Recent dovecot.log:"
  docker compose exec -T ms bash -c 'tail -n 80 /var/log/dovecot.log 2>/dev/null || true'
  exit 1
fi

if printf '%s\n' "$imap_out" | grep -qiE 'Logged in as \(null\)'; then
  echo "FAIL: IMAP session looks broken (null CAPABILITY)"
  printf '%s\n' "$imap_out" | tail -n 40
  exit 1
fi

echo "IMAP LOGIN over 993 succeeded"

echo "==> Checking Dovecot quota config has no invalid warning rules"
quota_errs="$(
  docker compose exec -T ms bash -c \
    'grep -E "Invalid warning rule|Failed to initialize quota" /var/log/dovecot.log 2>/dev/null || true'
)"
if [ -n "${quota_errs}" ]; then
  echo "FAIL: dovecot.log reports invalid quota warning / quota init failure:"
  printf '%s\n' "$quota_errs"
  exit 1
fi
echo "No invalid quota warning rules in dovecot.log"
