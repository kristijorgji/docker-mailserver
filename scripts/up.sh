#!/usr/bin/env bash
#
# Start the mailserver stack from the install root.
#
# When enable_webmail: true in configs/vars/vars.yml, includes SnappyMail automatically
# and seeds domain IMAP/SMTP backends to ms:993 / ms:465.
# Usage: ./scripts/up.sh [docker compose up options]
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

COMPOSE_FILES=(-f docker-compose.yml)
PROFILES=()
WEBMAIL=0

if [ -f docker-compose.webmail.yml ] && grep -Eq '^[[:space:]]*enable_webmail:[[:space:]]*true' configs/vars/vars.yml 2>/dev/null; then
  COMPOSE_FILES+=(-f docker-compose.webmail.yml)
  PROFILES+=(--profile webmail)
  WEBMAIL=1
fi

docker compose "${COMPOSE_FILES[@]}" "${PROFILES[@]}" up -d "$@"

if [ "$WEBMAIL" -eq 1 ]; then
  # SnappyMail creates _data_ on first start; retry briefly before seeding.
  for _ in $(seq 1 24); do
    if [ -d "${ROOT}/data/snappymail/_data_/_default_" ] || [ -f "${ROOT}/data/snappymail/INSTALLED" ]; then
      break
    fi
    sleep 1
  done
  "${ROOT}/scripts/seed-snappymail-domains.sh" "$ROOT"
fi
