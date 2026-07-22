#!/usr/bin/env bash
#
# Create a tarball backup of MySQL data and maildir.
#
# Output: ./backups/mailserver-YYYY-MM-DD_HHMMSS.tar.gz
# Usage: ./scripts/backup/backup.sh
# Env:   BACKUP_DIR (default ./backups), MAILSERVER_MAILS_PATH (default ./mail)
#
# MySQL/maildir files are often owned by container UIDs the host user cannot
# read. Prefer a short-lived root helper container that mounts those paths;
# fall back to host tar when Docker is unavailable.
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MAIL_PATH="${MAILSERVER_MAILS_PATH:-./mail}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
TIMESTAMP="$(date +%Y-%m-%d_%H%M%S)"
ARCHIVE_NAME="mailserver-${TIMESTAMP}.tar.gz"
ARCHIVE="${BACKUP_DIR}/${ARCHIVE_NAME}"

mkdir -p "$BACKUP_DIR"

if [ ! -d "./data/mysql" ] && [ ! -d "$MAIL_PATH" ]; then
  echo "Nothing to back up: ./data/mysql and ${MAIL_PATH} not found."
  exit 1
fi

echo "Creating backup archive: ${ARCHIVE}"

abs_path() {
  local p="$1"
  if [ -d "$p" ]; then
    (cd "$p" && pwd)
  else
    echo "${ROOT_DIR}/${p#./}"
  fi
}

MYSQL_ABS="$(abs_path ./data/mysql)"
MAIL_ABS="$(abs_path "$MAIL_PATH")"
BACKUP_ABS="$(abs_path "$BACKUP_DIR")"

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  # Archive layout: data/mysql/... and mail/... (same as host-relative paths)
  docker run --rm \
    -v "${MYSQL_ABS}:/backup/data/mysql:ro" \
    -v "${MAIL_ABS}:/backup/mail:ro" \
    -v "${BACKUP_ABS}:/out" \
    alpine:3.20 \
    tar -czf "/out/${ARCHIVE_NAME}" -C /backup data/mysql mail
else
  tar -czf "$ARCHIVE" ./data/mysql "$MAIL_PATH"
fi

echo "Backup complete: ${ARCHIVE}"
echo "Note: external TLS certificates (tls_cert_mode: external) are not included."
