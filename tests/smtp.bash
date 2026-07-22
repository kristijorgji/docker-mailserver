#!/usr/bin/env bash
# Basic SMTP connectivity test (requires swaks: apt install swaks / brew install swaks)
set -euo pipefail

DOMAIN="${MAIL_TEST_DOMAIN:-example.com}"
TO="${MAIL_TEST_TO:-me@example.com}"

if ! command -v swaks >/dev/null 2>&1; then
  echo "swaks not installed; skipping SMTP send test"
  exit 0
fi

swaks --to "$TO" --from "test@$DOMAIN" --server localhost --port 25 --header "Subject: smoke test" --body "test" \
  | grep -qE '250|550|554'

echo "SMTP test completed"
