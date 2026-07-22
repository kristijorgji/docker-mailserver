#!/usr/bin/env bash
# Verify that git hooks are properly installed
# Exits with non-zero status if hooks are not configured correctly

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

ERRORS=0

# Check if core.hooksPath is set correctly
HOOKS_PATH=$(git config core.hooksPath 2>/dev/null || echo "")
if [ "$HOOKS_PATH" != "git_hooks" ] && [ "$HOOKS_PATH" != "./git_hooks" ]; then
	echo "ERROR: Git hooks not configured!"
	echo "  Expected: git config core.hooksPath = git_hooks"
	echo "  Actual:   git config core.hooksPath = ${HOOKS_PATH:-<not set>}"
	echo ""
	echo "Run: bash scripts/dev-init.sh"
	ERRORS=1
fi

# Check if pre-commit hook exists
if [ ! -f "git_hooks/pre-commit" ]; then
	echo "ERROR: pre-commit hook not found: git_hooks/pre-commit"
	ERRORS=1
fi

# Check if pre-commit hook is executable
if [ -f "git_hooks/pre-commit" ] && [ ! -x "git_hooks/pre-commit" ]; then
	echo "ERROR: pre-commit hook is not executable: git_hooks/pre-commit"
	echo "Run: chmod +x git_hooks/pre-commit"
	ERRORS=1
fi

# Check if pre-commit.d directory exists
if [ ! -d "git_hooks/pre-commit.d" ]; then
	echo "ERROR: pre-commit.d directory not found: git_hooks/pre-commit.d"
	ERRORS=1
fi

# Check if individual hooks exist and are executable
if [ -d "git_hooks/pre-commit.d" ]; then
	for hook in git_hooks/pre-commit.d/*; do
		if [ -f "$hook" ] && [ ! -x "$hook" ]; then
			echo "WARNING: Hook is not executable: $hook"
			echo "Run: chmod +x $hook"
		fi
	done
fi

if [ $ERRORS -eq 0 ]; then
	echo "✓ Git hooks are properly configured"
	exit 0
else
	exit 1
fi
