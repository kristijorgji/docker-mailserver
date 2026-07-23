#!/usr/bin/env bash
#
# Point SnappyMail domain backends at the ms container (Docker network).
# Stock SnappyMail defaults use localhost:143/25, which fails in the sidecar layout
# (Dovecot IMAPS is on ms:993; plain 143 is off by default).
#
# Safe to re-run: only replaces default.json when missing or still localhost IMAP,
# and patches other domain JSON files that still use localhost / port 143.
#
# Usage: ./scripts/seed-snappymail-domains.sh [install-root]
#
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
SEED="${2:-${ROOT}/configs/snappymail/default.json}"
DOMAINS_DIR="${ROOT}/data/snappymail/_data_/_default_/domains"

if [[ ! -f "$SEED" ]]; then
  echo "seed-snappymail-domains: missing seed ${SEED}" >&2
  exit 1
fi

mkdir -p "$DOMAINS_DIR"

needs_ms_backends() {
  local file="$1"
  python3 - "$file" <<'PY'
import json, sys
path = sys.argv[1]
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
except (OSError, json.JSONDecodeError):
    sys.exit(0)  # treat unreadable/broken as needing replace
imap = data.get("IMAP") or {}
host = str(imap.get("host", "")).lower()
port = int(imap.get("port") or 0)
if host in ("localhost", "127.0.0.1") or port == 143:
    sys.exit(0)
sys.exit(1)
PY
}

if [[ ! -f "${DOMAINS_DIR}/default.json" ]] || needs_ms_backends "${DOMAINS_DIR}/default.json"; then
  cp "$SEED" "${DOMAINS_DIR}/default.json"
  echo "seed-snappymail-domains: wrote ${DOMAINS_DIR}/default.json"
fi

shopt -s nullglob
for domain_json in "${DOMAINS_DIR}"/*.json; do
  base="$(basename "$domain_json")"
  [[ "$base" == "default.json" ]] && continue
  if needs_ms_backends "$domain_json"; then
    python3 - "$domain_json" "$SEED" <<'PY'
import json, sys
path, seed_path = sys.argv[1], sys.argv[2]
with open(seed_path, encoding="utf-8") as f:
    seed = json.load(f)
with open(path, encoding="utf-8") as f:
    data = json.load(f)
# Preserve shortLogin and other per-domain prefs; replace connection backends.
for proto in ("IMAP", "SMTP", "Sieve"):
    if proto not in data:
        data[proto] = dict(seed[proto])
        continue
    short = data[proto].get("shortLogin", seed[proto].get("shortLogin"))
    data[proto] = dict(seed[proto])
    data[proto]["shortLogin"] = short
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=4)
    f.write("\n")
print(f"seed-snappymail-domains: patched {path}")
PY
  fi
done
