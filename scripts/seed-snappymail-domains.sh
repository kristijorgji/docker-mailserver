#!/usr/bin/env bash
#
# Point SnappyMail domain backends at the ms container (Docker network).
# Stock SnappyMail defaults use localhost:143/25 and SCRAM SASL, which fail with
# this stack (Dovecot IMAPS on ms:993; auth_mechanisms = plain login only).
#
# Idempotent: rewrites domain JSON when backends/SASL/shortLogin diverge from the seed.
#
# Usage: ./scripts/seed-snappymail-domains.sh [install-root] [seed-json]
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

needs_seed_fix() {
  local file="$1"
  python3 - "$file" "$SEED" <<'PY'
import json, sys

path, seed_path = sys.argv[1], sys.argv[2]
with open(seed_path, encoding="utf-8") as f:
    seed = json.load(f)
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
except (OSError, json.JSONDecodeError):
    sys.exit(0)

def diverges(proto: str) -> bool:
    want = seed.get(proto) or {}
    have = data.get(proto) or {}
    for key in ("host", "port", "type", "shortLogin", "sasl"):
        if have.get(key) != want.get(key):
            return True
    if proto == "SMTP" and have.get("useAuth") != want.get("useAuth"):
        return True
    return False

for proto in ("IMAP", "SMTP", "Sieve"):
    if diverges(proto):
        sys.exit(0)
sys.exit(1)
PY
}

apply_seed_backends() {
  local file="$1"
  python3 - "$file" "$SEED" <<'PY'
import json, sys

path, seed_path = sys.argv[1], sys.argv[2]
with open(seed_path, encoding="utf-8") as f:
    seed = json.load(f)
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
except (OSError, json.JSONDecodeError):
    data = {}

# Full replace of connection backends from seed (shortLogin forced false via seed).
for proto in ("IMAP", "SMTP", "Sieve"):
    data[proto] = dict(seed[proto])

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=4)
    f.write("\n")
print(f"seed-snappymail-domains: updated {path}")
PY
}

if [[ ! -f "${DOMAINS_DIR}/default.json" ]] || needs_seed_fix "${DOMAINS_DIR}/default.json"; then
  apply_seed_backends "${DOMAINS_DIR}/default.json"
fi

shopt -s nullglob
for domain_json in "${DOMAINS_DIR}"/*.json; do
  base="$(basename "$domain_json")"
  [[ "$base" == "default.json" ]] && continue
  if needs_seed_fix "$domain_json"; then
    apply_seed_backends "$domain_json"
  fi
done
