#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

OUT_DIR="release/dependency"
MODULES_FILE="$OUT_DIR/modules.txt"
UPDATES_FILE="$OUT_DIR/updates.txt"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

mkdir -p "$OUT_DIR"

echo "== go module list =="
GOWORK=off go list -m all | tee "$MODULES_FILE"

main_module="$(GOWORK=off go list -m)"
if awk -v main="$main_module" '$1 != main { found = 1 } END { exit found ? 0 : 1 }' "$MODULES_FILE"; then
  echo
  awk -v main="$main_module" '$1 != main { print "external module:", $0 }' "$MODULES_FILE" >&2
  fail "kernel must remain standard-library-only"
fi

echo
echo "== available module updates =="
GOWORK=off go list -m -u all | tee "$UPDATES_FILE"

echo
echo "== go mod tidy check =="
GOWORK=off go mod tidy

dirty="$(git status --short -- go.mod go.sum)"
if [ -n "$dirty" ]; then
  echo "$dirty" >&2
  fail "go.mod/go.sum changed after GOWORK=off go mod tidy"
fi

echo "dependency diff check passed"
