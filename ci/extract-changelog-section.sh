#!/usr/bin/env bash
# Extract a version section from CHANGELOG.md for GitHub Release notes.
set -euo pipefail

VERSION="${1:-}"
CHANGELOG="${2:-CHANGELOG.md}"

if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version> [changelog-file]" >&2
  exit 1
fi

VERSION="${VERSION#v}"

awk -v ver="$VERSION" '
  $0 ~ "^## \\[" ver "\\]" { found=1; next }
  found && /^## \[/ { exit }
  found { print }
' "$CHANGELOG"
