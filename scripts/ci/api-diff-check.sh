#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
SNAPSHOT="contracts/public_api.snapshot"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

GOWORK=off go list -json ./contracttest ./errx ./healthx ./lifecycx ./obsx ./retryx ./syncx ./timex ./validx ./versionx \
  | GOWORK=off go run ./scripts/ci/internal/apisnapshot > "$TMP"

if [ "${UPDATE_PUBLIC_API_SNAPSHOT:-}" = "1" ] || [ "${1:-}" = "--update" ]; then
  cp "$TMP" "$SNAPSHOT"
  echo "public API snapshot updated: $SNAPSHOT"
  exit 0
fi

[ -s "$SNAPSHOT" ] || { echo "ERROR: public API snapshot missing or empty: $SNAPSHOT"; exit 1; }
if ! diff -u "$SNAPSHOT" "$TMP"; then
  echo "ERROR: public API snapshot drift detected; run UPDATE_PUBLIC_API_SNAPSHOT=1 ./scripts/ci/api-diff-check.sh after intentional API review"
  exit 1
fi

echo "public API snapshot check passed"
