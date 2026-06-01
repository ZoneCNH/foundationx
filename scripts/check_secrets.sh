#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "checking secrets..."

PATTERNS=(
  "password="
  "passwd="
  "secret="
  "token="
  "access_key="
  "secret_key="
  "AKIA[0-9A-Z]{16}"
  "BEGIN RSA PRIVATE KEY"
  "BEGIN OPENSSH PRIVATE KEY"
  "BEGIN PRIVATE KEY"
)

for pattern in "${PATTERNS[@]}"; do
  if find . -type f \
    ! -path './.git/*' \
    ! -path './.omx/*' \
    ! -path './.worktree/*' \
    ! -path './vendor/*' \
    ! -path './AGENTS.md' \
    ! -path './docs/goal.md' \
    ! -path './scripts/check_secrets.sh' \
    ! -name '*.sum' \
    -print0 | xargs -0 grep -I -E -n "$pattern" >/tmp/kernel-secret-scan.txt; then
    cat /tmp/kernel-secret-scan.txt
    echo "ERROR: possible secret found: $pattern"
    rm -f /tmp/kernel-secret-scan.txt
    exit 1
  fi
done

rm -f /tmp/kernel-secret-scan.txt
echo "secret check passed"
