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

config_section_value() {
  local section="$1"
  local key="$2"
  awk -v section="$section" -v key="$key" '
    $0 ~ "^" section ":" {
      in_section = 1
      next
    }
    in_section && /^[^[:space:]]/ {
      exit
    }
    in_section {
      pattern = "^[[:space:]]+" key ":[[:space:]]*"
      if ($0 ~ pattern) {
        value = $0
        sub(pattern, "", value)
        gsub(/^"|"$/, "", value)
        print value
        exit
      }
    }
  ' "$CONFIG"
}

[ -s "$CONFIG" ] || fail "$CONFIG missing or empty"

require_config_key '^standard_source:'
require_config_key '^[[:space:]]+repo:[[:space:]]+ZoneCNH/xlib-standard$'
require_config_key '^target:'
require_config_key '^[[:space:]]+repo:[[:space:]]+ZoneCNH/kernel$'
require_config_key '^last_synced:'
require_config_key '^drift_check:'
require_config_key '^[[:space:]]+default_mode:[[:space:]]+local-pinned-baseline$'
require_config_key '^[[:space:]]+live_network_gate:[[:space:]]+false$'

baseline_commit="$(config_section_value last_synced commit)"
baseline_date="$(config_section_value last_synced date)"
baseline_evidence="$(config_section_value last_synced evidence)"

if ! printf '%s\n' "$baseline_commit" | grep -Eq '^[0-9a-f]{40}$'; then
  fail "$CONFIG last_synced.commit must be a 40-character lowercase git commit"
fi

if ! printf '%s\n' "$baseline_date" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
  fail "$CONFIG last_synced.date must use YYYY-MM-DD"
fi

[ -n "$baseline_evidence" ] || fail "$CONFIG last_synced.evidence missing"
[ -s "$baseline_evidence" ] || fail "baseline evidence missing or empty: $baseline_evidence"

mkdir -p "$OUT_DIR"

generated_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
{
  echo "# kernel standard sync report"
  echo
  echo "- generated_at: $generated_at"
  echo "- config: $CONFIG"
  echo "- source: ZoneCNH/xlib-standard"
  echo "- source_baseline_commit: $baseline_commit"
  echo "- source_baseline_date: $baseline_date"
  echo "- source_baseline_evidence: $baseline_evidence"
  echo "- target: ZoneCNH/kernel"
  echo "- default_mode: local-pinned-baseline"
  echo "- live_network_gate: false"
  echo
  echo "## Local standard evidence"
  echo
  echo "Required local evidence:"
} > "$REPORT"

required_evidence=(
  "$CONFIG"
  "$baseline_evidence"
  "docs/context/xlib-standard-contract.md"
  "docs/governance/KERNEL_FOUNDATION_RULES.md"
  "docs/governance/RELEASE_MANIFEST_SCHEMA.md"
  "contracts/error.schema.json"
  "contracts/health.schema.json"
  "contracts/version.schema.json"
  "contracts/public_api.snapshot"
  "scripts/check_docs.sh"
  "scripts/check_contracts.sh"
  "scripts/check_boundary.sh"
  "scripts/generate_manifest.sh"
  "scripts/check_release_evidence.sh"
)

for evidence_path in "${required_evidence[@]}"; do
  [ -s "$evidence_path" ] || fail "required local standard evidence missing or empty: $evidence_path"
  echo "- $evidence_path" >> "$REPORT"
done

{
  echo
  echo "Local gate statement:"
  echo "- upstream fetch: not run by default"
  echo "- comparison basis: pinned reviewed baseline plus local governance and contract artifacts"
  echo "- default gate scope: local filesystem only"
  echo
  echo "## Local forbidden token check"
  echo
  echo "Implementation surfaces scanned:"
} >> "$REPORT"

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
  echo "- required local standard evidence: passed"
  echo "- forbidden template tokens: passed"
} >> "$REPORT"

echo "standard drift local check passed"
