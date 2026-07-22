#!/usr/bin/env bash
#
# Start the mailserver stack from the install root.
#
# When enable_webmail: true in configs/vars/vars.yml, includes SnappyMail automatically.
# Usage: ./scripts/up.sh [docker compose up options]
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

exec docker compose "${COMPOSE_FILES[@]}" "${PROFILES[@]}" up -d "$@"
