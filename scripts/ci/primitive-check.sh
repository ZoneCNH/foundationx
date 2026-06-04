#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FAIL=0

echo "primitive-check: verifying L0 primitive packages..."

# All packages that should have standard artifacts
PACKAGES=(contextx contracttest errx healthx lifecycx obsx retryx shutdownx syncx timex validx versionx)

for pkg in "${PACKAGES[@]}"; do
  dir="$ROOT/$pkg"
  if [[ ! -d "$dir" ]]; then
    echo "FAIL: package directory missing: $pkg"
    FAIL=1
    continue
  fi

  # Check for source file
  if ! ls "$dir"/*.go 2>/dev/null | grep -v _test.go >/dev/null 2>&1; then
    echo "FAIL: no source file in $pkg"
    FAIL=1
  fi

  # Check for test file
  if ! ls "$dir"/*_test.go 2>/dev/null >/dev/null 2>&1; then
    echo "FAIL: no test file in $pkg"
    FAIL=1
  fi

  # Check for README
  if [[ ! -f "$dir/README.md" ]]; then
    echo "FAIL: no README.md in $pkg"
    FAIL=1
  fi
done

# Check maturity matrix covers all packages
MATURITY="$ROOT/docs/governance/PACKAGE_MATURITY.md"
if [[ -f "$MATURITY" ]]; then
  for pkg in "${PACKAGES[@]}"; do
    if ! grep -q "$pkg" "$MATURITY"; then
      echo "FAIL: $pkg not in PACKAGE_MATURITY.md"
      FAIL=1
    fi
  done
else
  echo "FAIL: PACKAGE_MATURITY.md not found"
  FAIL=1
fi

# Check API snapshot covers all packages
SNAPSHOT="$ROOT/contracts/public_api.snapshot"
if [[ -f "$SNAPSHOT" ]]; then
  for pkg in "${PACKAGES[@]}"; do
    if ! grep -q "^[a-z]* $pkg\.\|^func $pkg\.\|^type $pkg\.\|^const $pkg\.\|^field $pkg\.\|^method $pkg\.\|^var $pkg\." "$SNAPSHOT" 2>/dev/null; then
      echo "FAIL: $pkg not in public_api.snapshot"
      FAIL=1
    fi
  done
else
  echo "FAIL: public_api.snapshot not found"
  FAIL=1
fi

if [[ $FAIL -eq 0 ]]; then
  echo "primitive-check: ok"
else
  echo "primitive-check: FAILED"
  exit 1
fi
