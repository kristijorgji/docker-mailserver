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

echo "This will overwrite ./data/mysql and ${MAIL_PATH} from:"
echo "  $ARCHIVE"
if [ "${RESTORE_SKIP_CONFIRM:-}" != "1" ]; then
  read -r -p "Type 'yes' to continue: " CONFIRM
  if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 1
  fi
fi

if command -v docker-compose >/dev/null 2>&1; then
  docker-compose stop ms 2>/dev/null || true
elif command -v docker >/dev/null 2>&1; then
  docker compose stop ms 2>/dev/null || true
fi

mkdir -p ./data/mysql "$MAIL_PATH"
tar -xzf "$ARCHIVE" -C "$ROOT_DIR"

if command -v docker-compose >/dev/null 2>&1; then
  docker-compose up -d ms
elif command -v docker >/dev/null 2>&1; then
  docker compose up -d ms
fi

if [ -x ./update.sh ]; then
  ./update.sh
fi

echo "Restore complete. Verify mail and accounts before returning to production use."
