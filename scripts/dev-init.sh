#!/usr/bin/env bash
#
# One-time developer bootstrap after git clone.
# Configures git hooks, executable bits, vault template, and dev data dirs.
#
# Usage: bash scripts/dev-init.sh
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> Configuring git hooks"
git config core.hooksPath git_hooks

echo "==> Making scripts executable"
chmod +x git_hooks/pre-commit 2>/dev/null || true
chmod +x git_hooks/pre-commit.d/* 2>/dev/null || true
chmod +x scripts/*.sh scripts/backup/*.sh update.sh install.sh tests/*.bash 2>/dev/null || true

VAULT_FILE="configs/vars/vault.yml"
if [ ! -f "$VAULT_FILE" ]; then
	echo "==> Creating $VAULT_FILE from vault.example.yml"
	cp configs/vars/vault.example.yml "$VAULT_FILE"
	echo "    Edit $VAULT_FILE — replace CHANGE_ME passwords before boot."
else
	echo "==> $VAULT_FILE already exists (not overwritten)"
fi

echo "==> Creating dev data directories"
mkdir -p data/mysql data/letsencrypt mail backups

echo "==> Verifying git hooks"
./scripts/check-hooks.sh

cat <<'EOF'

Developer setup complete.

Next steps:
  1. Edit configs/vars/vault.yml — use non-CHANGE_ME passwords
  2. docker compose up -d --build
  3. ./update.sh
  4. bash tests/smoke.bash

EOF
