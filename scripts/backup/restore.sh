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

ARCHIVE_ABS="$(cd "$(dirname "$ARCHIVE")" && pwd)/$(basename "$ARCHIVE")"

# Bind mounts are often owned by container UIDs. Wipe + extract as root in a
# helper container, then fix ownership for mysql/vmail inside the ms image.
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  docker run --rm \
    -v "${ROOT_DIR}:/restore" \
    -v "${ARCHIVE_ABS}:/backup.tar.gz:ro" \
    alpine:3.20 \
    sh -c 'rm -rf /restore/data/mysql /restore/mail && mkdir -p /restore/data /restore/mail && tar -xzf /backup.tar.gz -C /restore'

  if [ "${#COMPOSE[@]}" -gt 0 ]; then
    "${COMPOSE[@]}" run --rm --no-deps --entrypoint bash ms -c \
      'chown -R mysql:mysql /var/lib/mysql; chown -R vmail:vmail /var/mail'
  fi
else
  rm -rf ./data/mysql "${MAIL_PATH}"
  mkdir -p ./data/mysql "$MAIL_PATH"
  tar -xzf "$ARCHIVE" -C "$ROOT_DIR"
fi

if [ "${#COMPOSE[@]}" -gt 0 ]; then
  "${COMPOSE[@]}" up -d ms
fi

if [ -x ./update.sh ]; then
  ./update.sh
fi

echo "Restore complete. Verify mail and accounts before returning to production use."
