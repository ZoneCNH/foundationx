#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CONFIG=".standard-sync.yaml"
OUT_DIR="release/standard-sync"
REPORT="$OUT_DIR/latest.md"

fail() {
  if [ -n "${REPORT:-}" ] && [ -d "$OUT_DIR" ]; then
    {
      echo
      echo "## Result"
      echo
      echo "- status: failed"
      echo "- reason: $*"
    } >> "$REPORT"
  fi
  echo "ERROR: $*" >&2
  exit 1
}

require_config_key() {
  local key="$1"
  if ! grep -Eq "$key" "$CONFIG"; then
    fail "$CONFIG missing required entry matching: $key"
  fi
}

[ -s "$CONFIG" ] || fail "$CONFIG missing or empty"

require_config_key '^standard_source:'
require_config_key '^[[:space:]]+repo:[[:space:]]+ZoneCNH/xlib-standard$'
require_config_key '^target:'
require_config_key '^[[:space:]]+repo:[[:space:]]+ZoneCNH/kernel$'

mkdir -p "$OUT_DIR"

generated_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
{
  echo "# kernel standard sync report"
  echo
  echo "- generated_at: $generated_at"
  echo "- config: $CONFIG"
  echo "- source: ZoneCNH/xlib-standard"
  echo "- target: ZoneCNH/kernel"
  echo
  echo "## Local forbidden token check"
  echo
  echo "Implementation surfaces scanned:"
} > "$REPORT"

surfaces=()
for path in \
  go.mod \
  go.sum \
  Makefile \
  scripts \
  errx \
  timex \
  lifecycx \
  retryx \
  healthx \
  obsx \
  validx \
  syncx \
  versionx \
  contracttest \
  internal \
  examples \
  contracts \
  pkg; do
  if [ -e "$path" ]; then
    surfaces+=("$path")
    echo "- $path" >> "$REPORT"
  fi
done

[ "${#surfaces[@]}" -gt 0 ] || fail "no implementation surfaces found"

for forbidden_path in "pkg/"'templatex'; do
  if [ -e "$forbidden_path" ]; then
    fail "forbidden standard/template path found: $forbidden_path"
  fi
done

tokens=(
  "pkg/"'templatex'
  "package "'templatex'
  "github.com/ZoneCNH/"'baselib-template'
)

for token in "${tokens[@]}"; do
  if matches="$(grep -R -n -F -- "$token" "${surfaces[@]}" || true)" && [ -n "$matches" ]; then
    {
      echo
      echo "### Forbidden token"
      echo
      echo "\`\`\`text"
      printf '%s\n' "$matches"
      echo "\`\`\`"
    } >> "$REPORT"
    fail "forbidden standard/template token found: $token"
  fi
done

{
  echo
  echo "## Result"
  echo
  echo "- status: passed"
  echo "- forbidden template tokens: passed"
} >> "$REPORT"

echo "standard drift local check passed"
