#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  echo "ERROR: $*"
  exit 1
}

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  fail "release clean check requires a git worktree"
fi

status="$(git status --short --untracked-files=all -- .)"
status="$(printf '%s\n' "$status" | grep -vE '^.. release/(manifest/[^/]+\.json(\.sha256)?|dependency/(modules|updates)\.txt|standard-sync/latest\.md)$' || true)"

if [ -n "$status" ]; then
  echo "ERROR: release workspace is dirty"
  printf '%s\n' "$status"
  exit 1
fi

echo "release workspace clean"
