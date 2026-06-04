#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FAIL=0

echo "kernel-admission-check: verifying new package admission..."

# Candidate packages that must pass admission
CANDIDATES=(contextx shutdownx)

for pkg in "${CANDIDATES[@]}"; do
  dir="$ROOT/$pkg"
  echo "  checking $pkg..."

  # 1. Must have an ADR
  if ! grep -rl "$pkg" "$ROOT/docs/adr/" 2>/dev/null | head -1 >/dev/null 2>&1; then
    echo "FAIL: $pkg has no ADR in docs/adr/"
    FAIL=1
  fi

  # 2. Must have package directory
  if [[ ! -d "$dir" ]]; then
    echo "FAIL: $pkg directory missing"
    FAIL=1
    continue
  fi

  # 3. Must have tests
  if ! ls "$dir"/*_test.go 2>/dev/null >/dev/null 2>&1; then
    echo "FAIL: $pkg has no tests"
    FAIL=1
  fi

  # 4. Must be in PACKAGE_MATURITY.md as candidate
  MATURITY="$ROOT/docs/governance/PACKAGE_MATURITY.md"
  if [[ -f "$MATURITY" ]]; then
    if grep -q "$pkg" "$MATURITY"; then
      if ! grep -A2 "$pkg" "$MATURITY" | grep -qi "candidate"; then
        echo "FAIL: $pkg is not marked as candidate in PACKAGE_MATURITY.md"
        FAIL=1
      fi
    else
      echo "FAIL: $pkg not in PACKAGE_MATURITY.md"
      FAIL=1
    fi
  fi
done

if [[ $FAIL -eq 0 ]]; then
  echo "kernel-admission-check: ok"
else
  echo "kernel-admission-check: FAILED"
  exit 1
fi
