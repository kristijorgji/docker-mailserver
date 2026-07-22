#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

MARKER_FILE="./mail/ci-backup-marker"
MARKER_CONTENT="backup-restore-ci-$(date +%s)"

echo "==> Creating maildir marker for restore verification"
mkdir -p ./mail
echo "$MARKER_CONTENT" > "$MARKER_FILE"

echo "==> Recording MySQL virtual_users count"
count_before=$(docker compose exec -T ms bash -c \
  "mysql --defaults-file=/root/.my.cnf -N -e 'SELECT COUNT(*) FROM mailserver.virtual_users'")
test "$count_before" -ge 1

echo "==> Running backup"
chmod +x scripts/backup/backup.sh scripts/backup/restore.sh
bash scripts/backup/backup.sh
ARCHIVE="$(ls -t backups/mailserver-*.tar.gz | head -1)"
test -f "$ARCHIVE"

echo "==> Stopping container and removing data directories"
docker compose stop ms

# Container UIDs own these bind mounts; wipe via root helper (host rm fails on CI).
docker run --rm \
  -v "${ROOT_DIR}/data/mysql:/wipe-mysql" \
  -v "${ROOT_DIR}/mail:/wipe-mail" \
  alpine:3.20 \
  sh -c 'rm -rf /wipe-mysql/* /wipe-mysql/.[!.]* /wipe-mysql/..?* 2>/dev/null; rm -rf /wipe-mail/* /wipe-mail/.[!.]* /wipe-mail/..?* 2>/dev/null; true'
mkdir -p ./data/mysql ./mail

echo "==> Restoring from ${ARCHIVE}"
RESTORE_SKIP_CONFIRM=1 bash scripts/backup/restore.sh "$ARCHIVE"

echo "==> Waiting for Postfix after restore"
for i in $(seq 1 30); do
  if docker compose exec -T ms postfix status 2>/dev/null; then
    break
  fi
  sleep 5
done

echo "==> Verifying restored marker file"
test "$(cat "$MARKER_FILE")" = "$MARKER_CONTENT"

echo "==> Verifying restored MySQL accounts"
count_after=$(docker compose exec -T ms bash -c \
  "mysql --defaults-file=/root/.my.cnf -N -e 'SELECT COUNT(*) FROM mailserver.virtual_users'")
test "$count_after" -eq "$count_before"

docker compose exec -T ms postfix check
bash "$(dirname "$0")/imap-auth.bash"

echo "Backup/restore round-trip passed."
