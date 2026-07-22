#!/usr/bin/env bash
#
# Prove ./update.sh upserts apply vault changes (ON DUPLICATE KEY UPDATE).
# Changes mailbox quota for me@example.com, asserts MySQL, then restores vault.
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VAULT="configs/vars/vault.yml"
EMAIL="${MAIL_TEST_USER:-me@example.com}"
BACKUP="$(mktemp)"
trap 'rm -f "$BACKUP"' EXIT

if [ ! -f "$VAULT" ]; then
  echo "FAIL: $VAULT not found (copy vault.example.yml or CI fixture first)"
  exit 1
fi

cp "$VAULT" "$BACKUP"

quota_bytes() {
  docker compose exec -T ms bash -c \
    "mysql --defaults-file=/root/.my.cnf -N -e \"SELECT COALESCE(quota_bytes,0) FROM mailserver.virtual_users WHERE email='${EMAIL}'\"" \
    | tr -d '[:space:]'
}

set_account_quota() {
  local quota="$1"
  # Rewrite mail_accounts entry for EMAIL with an explicit quota (idempotent upsert input).
  python3 - "$VAULT" "$EMAIL" "$quota" <<'PY'
import re, sys
path, email, quota = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(path, encoding="utf-8").read()
# Match a single-line YAML map account entry containing this email
pattern = re.compile(
    r"^(\s*-\s*\{[^}]*name:\s*[\"']" + re.escape(email) + r"[\"'][^}]*)\}",
    re.M,
)
m = pattern.search(text)
if not m:
    sys.exit(f"FAIL: could not find mail_accounts entry for {email} in {path}")
body = m.group(1)
body = re.sub(r",\s*quota:\s*[^,}]+", "", body)
body = body.rstrip() + f", quota: {quota}"
text = text[: m.start()] + body + "}" + text[m.end() :]
open(path, "w", encoding="utf-8").write(text)
PY
}

echo "==> Checking upsert applies quota change via ./update.sh"

set_account_quota "1G"
./update.sh >/dev/null
got="$(quota_bytes)"
want="1073741824"
if [ "$got" != "$want" ]; then
  echo "FAIL: after quota 1G expected ${want}, got ${got}"
  cp "$BACKUP" "$VAULT"
  ./update.sh >/dev/null || true
  exit 1
fi
echo "quota_bytes after 1G: ${got}"

set_account_quota "2G"
./update.sh >/dev/null
got="$(quota_bytes)"
want="2147483648"
if [ "$got" != "$want" ]; then
  echo "FAIL: after quota 2G expected ${want}, got ${got}"
  cp "$BACKUP" "$VAULT"
  ./update.sh >/dev/null || true
  exit 1
fi
echo "quota_bytes after 2G: ${got}"

echo "==> Restoring original vault and re-running ./update.sh"
cp "$BACKUP" "$VAULT"
./update.sh >/dev/null

echo "Upsert / update.sh tests passed."
