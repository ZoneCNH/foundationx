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
require_config_key '^[[:space:]]+live_network_mode:[[:space:]]+optional-fail-on-drift$'
require_config_key '^[[:space:]]+goalcli_sync:'
require_config_key '^[[:space:]]+mode:[[:space:]]+runtime-dependency-required$'
require_config_key '^[[:space:]]+adoption:[[:space:]]+required$'
require_config_key '^[[:space:]]+runtime_dependency:[[:space:]]+required$'
require_config_key '^[[:space:]]+dependency_module:[[:space:]]+github\.com/ZoneCNH/xlib-standard$'
require_config_key '^[[:space:]]+dependency_import_policy:[[:space:]]+public-go-package-required$'
require_config_key '^[[:space:]]+current_upstream_status:[[:space:]]+blocked-cmd-main-and-internal-only$'
require_config_key '^[[:space:]]+decision_evidence:[[:space:]]+docs/adr/ADR-20260604-001-goalcli-runtime-dependency.md$'
require_config_key '^[[:space:]]+copy_into_kernel:[[:space:]]+forbidden-without-approved-scope$'
require_config_key '^[[:space:]]+- cmd/goalcli/$'
require_config_key '^[[:space:]]+- internal/goalcli/$'
require_config_key '^[[:space:]]+- internal/goalruntime/$'
require_config_key '^[[:space:]]+- docs/standard/goalcli-cli-contract.md$'
require_config_key '^[[:space:]]+- docs/standard/goalcli-runtime.md$'
require_config_key '^[[:space:]]+- \.agent/standard/goalcli-mapping.md$'
require_config_key '^[[:space:]]+- contracts/goalcli-report.schema.json$'
require_config_key '^live_review:'

source_repo="$(config_section_value standard_source repo)"
source_branch="$(config_section_value standard_source branch)"
baseline_commit="$(config_section_value last_synced commit)"
baseline_date="$(config_section_value last_synced date)"
baseline_evidence="$(config_section_value last_synced evidence)"
live_review_checked_at="$(config_section_value live_review checked_at)"
live_review_commit="$(config_section_value live_review live_commit)"
live_review_relation="$(config_section_value live_review relation)"
live_review_decision="$(config_section_value live_review decision)"
live_review_evidence="$(config_section_value live_review evidence)"

[ -n "$source_repo" ] || fail "$CONFIG standard_source.repo missing"
[ -n "$source_branch" ] || fail "$CONFIG standard_source.branch missing"

if ! printf '%s\n' "$baseline_commit" | grep -Eq '^[0-9a-f]{40}$'; then
  fail "$CONFIG last_synced.commit must be a 40-character lowercase git commit"
fi

if ! printf '%s\n' "$baseline_date" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
  fail "$CONFIG last_synced.date must use YYYY-MM-DD"
fi

[ -n "$baseline_evidence" ] || fail "$CONFIG last_synced.evidence missing"
[ -s "$baseline_evidence" ] || fail "baseline evidence missing or empty: $baseline_evidence"

if ! printf '%s\n' "$live_review_checked_at" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
  fail "$CONFIG live_review.checked_at must use YYYY-MM-DD"
fi

if ! printf '%s\n' "$live_review_commit" | grep -Eq '^[0-9a-f]{40}$'; then
  fail "$CONFIG live_review.live_commit must be a 40-character lowercase git commit"
fi

[ -n "$live_review_relation" ] || fail "$CONFIG live_review.relation missing"
[ -n "$live_review_decision" ] || fail "$CONFIG live_review.decision missing"
[ -n "$live_review_evidence" ] || fail "$CONFIG live_review.evidence missing"
[ -s "$live_review_evidence" ] || fail "live review evidence missing or empty: $live_review_evidence"

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
  echo "- live_review_checked_at: $live_review_checked_at"
  echo "- live_review_commit: $live_review_commit"
  echo "- live_review_relation: $live_review_relation"
  echo "- live_review_decision: $live_review_decision"
  echo "- live_review_evidence: $live_review_evidence"
  echo "- target: ZoneCNH/kernel"
  echo "- default_mode: local-pinned-baseline"
  echo "- live_network_gate: false"
  echo "- live_network_mode: optional-fail-on-drift"
  echo
  echo "## Goalcli sync surface"
  echo
  echo "- mode: runtime-dependency-required"
  echo "- adoption: required"
  echo "- runtime_dependency: required"
  echo "- dependency_module: github.com/ZoneCNH/xlib-standard"
  echo "- dependency_import_policy: public-go-package-required"
  echo "- current_upstream_status: blocked-cmd-main-and-internal-only"
  echo "- decision_evidence: docs/adr/ADR-20260604-001-goalcli-runtime-dependency.md"
  echo "- copy_into_kernel: forbidden-without-approved-scope"
  echo "- source_paths:"
  echo "  - cmd/goalcli/"
  echo "  - internal/goalcli/"
  echo "  - internal/goalruntime/"
  echo "  - docs/standard/goalcli-cli-contract.md"
  echo "  - docs/standard/goalcli-runtime.md"
  echo "  - .agent/standard/goalcli-mapping.md"
  echo "  - contracts/goalcli-report.schema.json"
  echo
  echo "## Local standard evidence"
  echo
  echo "Required local evidence:"
} > "$REPORT"

required_evidence=(
  "$CONFIG"
  "docs/adr/ADR-20260604-001-goalcli-runtime-dependency.md"
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
  echo "- optional live check: run STANDARD_DRIFT_LIVE=1 ./scripts/check_standard_drift.sh"
  echo "- optional live behavior: fail when upstream main differs from the pinned reviewed baseline"
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

live_mode="${STANDARD_DRIFT_LIVE:-0}"
case "$live_mode" in
  0|false|FALSE|no|NO)
    {
      echo
      echo "## Live upstream check"
      echo
      echo "- status: not-run"
      echo "- reason: default local-pinned-baseline mode avoids network access"
      echo "- last_reviewed_live_commit: $live_review_commit"
      echo "- last_review_decision: $live_review_decision"
    } >> "$REPORT"
    ;;
  1|true|TRUE|yes|YES)
    live_commit="$(git ls-remote "https://github.com/$source_repo" "refs/heads/$source_branch" | awk '{print $1}')"
    [ -n "$live_commit" ] || fail "live upstream lookup returned no commit for $source_repo $source_branch"
    {
      echo
      echo "## Live upstream check"
      echo
      echo "- status: run"
      echo "- source_ref: $source_repo $source_branch"
      echo "- live_commit: $live_commit"
      echo "- pinned_baseline_commit: $baseline_commit"
    } >> "$REPORT"
    if [ "$live_commit" != "$baseline_commit" ]; then
      fail "live upstream drift detected: $source_repo $source_branch is $live_commit, pinned baseline is $baseline_commit"
    fi
    echo "- live drift: none" >> "$REPORT"
    ;;
  *)
    fail "STANDARD_DRIFT_LIVE must be 0/1, true/false, or yes/no"
    ;;
esac

{
  echo
  echo "## Result"
  echo
  echo "- status: passed"
  echo "- required local standard evidence: passed"
  echo "- forbidden template tokens: passed"
} >> "$REPORT"

echo "standard drift local check passed"
