#!/usr/bin/env bash
#
# Create a tarball backup of MySQL data and maildir.
#
# Output: ./backups/mailserver-YYYY-MM-DD_HHMMSS.tar.gz
# Usage: ./scripts/backup/backup.sh
# Env:   BACKUP_DIR (default ./backups), MAILSERVER_MAILS_PATH (default ./mail)
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MAIL_PATH="${MAILSERVER_MAILS_PATH:-./mail}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
TIMESTAMP="$(date +%Y-%m-%d_%H%M%S)"
ARCHIVE="${BACKUP_DIR}/mailserver-${TIMESTAMP}.tar.gz"

mkdir -p "$BACKUP_DIR"

if [ ! -d "./data/mysql" ] && [ ! -d "$MAIL_PATH" ]; then
  echo "Nothing to back up: ./data/mysql and ${MAIL_PATH} not found."
  exit 1
fi

echo "Creating backup archive: ${ARCHIVE}"
tar -czf "$ARCHIVE" \
  --exclude='./backups' \
  ./data/mysql \
  "$MAIL_PATH" \
  2>/dev/null || tar -czf "$ARCHIVE" ./data/mysql "$MAIL_PATH"

echo "Backup complete: ${ARCHIVE}"
echo "Note: external TLS certificates (tls_cert_mode: external) are not included."
