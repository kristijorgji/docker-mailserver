#!/usr/bin/env bash
#
# Restore MySQL + maildir from a backup archive (destructive overwrite).
#
# Prompts for confirmation (type 'yes'). Stops ms, extracts, starts, runs ./update.sh
# Usage: ./scripts/backup/restore.sh <backup-archive.tar.gz>
# Env:   MAILSERVER_MAILS_PATH (default ./mail), RESTORE_SKIP_CONFIRM=1 (skip prompt; CI only)
#
set -euo pipefail

if [ "${#}" -ne 1 ]; then
  echo "Usage: $(basename "$0") <backup-archive.tar.gz>"
  exit 1
fi

ARCHIVE="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

if [ ! -f "$ARCHIVE" ]; then
  echo "Backup archive not found: $ARCHIVE"
  exit 1
fi

MAIL_PATH="${MAILSERVER_MAILS_PATH:-./mail}"

if command -v docker-compose >/dev/null 2>&1; then
  COMPOSE=(docker-compose)
elif docker compose version >/dev/null 2>&1; then
  COMPOSE=(docker compose)
else
  COMPOSE=()
fi

echo "This will overwrite ./data/mysql and ${MAIL_PATH} from:"
echo "  $ARCHIVE"
if [ "${RESTORE_SKIP_CONFIRM:-}" != "1" ]; then
  read -r -p "Type 'yes' to continue: " CONFIRM
  if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 1
  fi
fi

if [ "${#COMPOSE[@]}" -gt 0 ]; then
  "${COMPOSE[@]}" stop ms 2>/dev/null || true
fi

mkdir -p ./data/mysql "$MAIL_PATH"

# Clear destinations as root when Docker is available (bind mounts are often
# owned by container UIDs the host user cannot delete).
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  MYSQL_ABS="$(cd ./data/mysql && pwd)"
  MAIL_ABS="$(cd "$MAIL_PATH" && pwd)"
  docker run --rm \
    -v "${MYSQL_ABS}:/wipe-mysql" \
    -v "${MAIL_ABS}:/wipe-mail" \
    alpine:3.20 \
    sh -c 'rm -rf /wipe-mysql/* /wipe-mysql/.[!.]* /wipe-mysql/..?* 2>/dev/null; rm -rf /wipe-mail/* /wipe-mail/.[!.]* /wipe-mail/..?* 2>/dev/null; true'
else
  rm -rf ./data/mysql/* "${MAIL_PATH:?}/"* 2>/dev/null || true
fi

tar -xzf "$ARCHIVE" -C "$ROOT_DIR"

# Bind-mounted files may be owned by the extracting host user; fix for container UIDs.
if [ "${#COMPOSE[@]}" -gt 0 ]; then
  "${COMPOSE[@]}" run --rm --no-deps --entrypoint bash ms -c \
    'chown -R mysql:mysql /var/lib/mysql; chown -R vmail:vmail /var/mail' \
    2>/dev/null || true
  "${COMPOSE[@]}" up -d ms
fi

if [ -x ./update.sh ]; then
  ./update.sh
fi

echo "Restore complete. Verify mail and accounts before returning to production use."
