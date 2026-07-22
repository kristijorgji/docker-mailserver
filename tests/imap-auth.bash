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
