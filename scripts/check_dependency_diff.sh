#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

OUT_DIR="release/dependency"
MODULES_FILE="$OUT_DIR/modules.txt"
UPDATES_FILE="$OUT_DIR/updates.txt"
DEPENDABOT_CONFIG=".github/dependabot.yml"
RENOVATE_CONFIG="renovate.json"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

mkdir -p "$OUT_DIR"

echo "== dependency automation config =="
[ -s "$DEPENDABOT_CONFIG" ] || fail "missing local dependency automation config: $DEPENDABOT_CONFIG"
[ -s "$RENOVATE_CONFIG" ] || fail "missing local dependency automation config: $RENOVATE_CONFIG"
grep -Eq 'package-ecosystem:[[:space:]]*"?gomod"?' "$DEPENDABOT_CONFIG" || fail "$DEPENDABOT_CONFIG missing gomod updater"
grep -Eq 'package-ecosystem:[[:space:]]*"?github-actions"?' "$DEPENDABOT_CONFIG" || fail "$DEPENDABOT_CONFIG missing github-actions updater"
grep -F '"gomod"' "$RENOVATE_CONFIG" >/dev/null || fail "$RENOVATE_CONFIG missing gomod manager"
grep -F '"github-actions"' "$RENOVATE_CONFIG" >/dev/null || fail "$RENOVATE_CONFIG missing github-actions manager"
echo "local automation config present: $DEPENDABOT_CONFIG"
echo "local automation config present: $RENOVATE_CONFIG"
echo "automation service execution: not run by default; scheduled services remain external to the local gate"
echo

echo "== go module list =="
GOWORK=off go list -m all | tee "$MODULES_FILE"

main_module="$(GOWORK=off go list -m)"
module_count="$(awk 'NF { count++ } END { print count + 0 }' "$MODULES_FILE")"
external_count="$(awk -v main="$main_module" '$1 != main { count++ } END { print count + 0 }' "$MODULES_FILE")"
echo "module count: $module_count"
echo "external module count: $external_count"
if [ "$external_count" -gt 0 ]; then
  echo
  awk -v main="$main_module" '$1 != main { print "external module:", $0 }' "$MODULES_FILE" >&2
  fail "kernel must remain standard-library-only"
fi

echo
echo "== available module updates =="
GOWORK=off go list -m -u all | tee "$UPDATES_FILE"
updates_count="$(awk 'NF { count++ } END { print count + 0 }' "$UPDATES_FILE")"
echo "update artifact line count: $updates_count"

echo
echo "== go mod tidy check =="
GOWORK=off go mod tidy

dirty="$(git status --short -- go.mod go.sum)"
if [ -n "$dirty" ]; then
  echo "$dirty" >&2
  fail "go.mod/go.sum changed after GOWORK=off go mod tidy"
fi

echo "dependency diff check passed"
