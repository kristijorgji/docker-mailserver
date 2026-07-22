#!/usr/bin/env bash
#
# Stop the mailserver stack (and SnappyMail when enable_webmail: true).
#
# Usage: ./scripts/down.sh [docker compose down options]
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

COMPOSE_FILES=(-f docker-compose.yml)
PROFILES=()

if [ -f docker-compose.webmail.yml ] && grep -Eq '^[[:space:]]*enable_webmail:[[:space:]]*true' configs/vars/vars.yml 2>/dev/null; then
  COMPOSE_FILES+=(-f docker-compose.webmail.yml)
  PROFILES+=(--profile webmail)
fi

exec docker compose "${COMPOSE_FILES[@]}" "${PROFILES[@]}" down "$@"
