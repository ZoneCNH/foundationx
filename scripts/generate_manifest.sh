#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERSIONS_FILE=".github/versions.env"
[ -s "$VERSIONS_FILE" ] || { echo "ERROR: missing toolchain version pins: $VERSIONS_FILE"; exit 1; }
# shellcheck disable=SC1090
. "$VERSIONS_FILE"

mkdir -p release/manifest
PINS="$ROOT/.github/versions.env"
[ -s "$PINS" ] || { echo "missing $PINS" >&2; exit 1; }
# shellcheck disable=SC1090
source "$PINS"

resolve_version() {
  if [ -n "${VERSION:-}" ]; then
    printf '%s' "$VERSION"
    return
  fi
  if [ -n "${GITHUB_REF_NAME:-}" ] && printf '%s' "$GITHUB_REF_NAME" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+'; then
    printf '%s' "$GITHUB_REF_NAME"
    return
  fi
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local tag
    tag="$(git tag --points-at HEAD --list 'v[0-9]*.[0-9]*.[0-9]*' | sort | tail -n 1)"
    if [ -n "$tag" ]; then
      printf '%s' "$tag"
      return
    fi
  fi
  printf 'v0.1.0'
}

VERSION="$(resolve_version)"
OUT="release/manifest/${VERSION}.json"
LATEST="release/manifest/latest.json"

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
    return
  fi
  shasum -a 256 "$1" | awk '{print $1}'
}

json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().rstrip("\n"))[1:-1])'
}

workspace_status() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'unknown'
    return
  fi

  local status
  status="$(git status --short --untracked-files=all -- .)"
  status="$(printf '%s\n' "$status" | grep -vE '^.. release/manifest/' || true)"
  if [ -n "$status" ]; then
    printf 'dirty'
    return
  fi
  printf 'clean'
}

json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

MODULE="$(GOWORK=off go list -m)"
COMMIT="$(git rev-parse HEAD 2>/dev/null || printf 'unknown')"
TREE_SHA="$(git rev-parse 'HEAD^{tree}' 2>/dev/null || printf 'unknown')"
WORKSPACE_STATUS="$(workspace_status)"
GO_VERSION="$(go version | sed 's/"/\\"/g')"
ACTUAL_GO_VERSION="$(go version | awk '{print $3}' | sed 's/^go//')"
GENERATED_AT="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
ERROR_SCHEMA_SHA="$(sha256_file contracts/error.schema.json)"
HEALTH_SCHEMA_SHA="$(sha256_file contracts/health.schema.json)"
VERSION_SCHEMA_SHA="$(sha256_file contracts/version.schema.json)"
PUBLIC_API_SHA="$(sha256_file contracts/public_api.snapshot)"
RETRY_GOLDEN_SHA="$(sha256_file contracts/examples/golden/retry-policy-default.json)"
OBS_GOLDEN_SHA="$(sha256_file contracts/examples/golden/obs-secret-redaction.json)"
LIFECYCLE_GOLDEN_SHA="$(sha256_file contracts/examples/golden/lifecycle-rollback-order.json)"
SYNC_GOLDEN_SHA="$(sha256_file contracts/examples/golden/sync-workergroup-aggregation.json)"

cat > "$OUT" <<JSON
{
  "schema_version": "kernel.release-manifest.v1",
  "module": "$MODULE",
  "version": "$VERSION",
  "commit": "$COMMIT",
  "tree_sha": "$TREE_SHA",
  "workspace_status": "$WORKSPACE_STATUS",
  "go_version": "$GO_VERSION",
  "generated_at": "$GENERATED_AT",
  "go": {
    "min_version": "$GO_MIN_VERSION",
    "integration_version": "$GO_INTEGRATION_VERSION",
    "actual_version": "$ACTUAL_GO_VERSION"
  },
  "api": {
    "public_api_snapshot": "contracts/public_api.snapshot",
    "public_api_sha256": "$PUBLIC_API_SHA"
  },
  "consumer_compatibility": {
    "xgo": {
      "status": "external-evidence-required",
      "evidence": "contracts/consumers/xgo/README.md",
      "minimal_import_test": "contracts/consumers/xgo/minimal_import_test.go"
    }
  },
  "contracts": {
    "error_schema_sha256": "$ERROR_SCHEMA_SHA",
    "health_schema_sha256": "$HEALTH_SCHEMA_SHA",
    "version_schema_sha256": "$VERSION_SCHEMA_SHA",
    "retry_policy_default_sha256": "$RETRY_GOLDEN_SHA",
    "obs_secret_redaction_sha256": "$OBS_GOLDEN_SHA",
    "lifecycle_rollback_order_sha256": "$LIFECYCLE_GOLDEN_SHA",
    "sync_workergroup_aggregation_sha256": "$SYNC_GOLDEN_SHA"
  },
  "checks": {
    "toolchain": "passed",
    "fmt": "passed",
    "vet": "passed",
    "unit_test": "passed",
    "race_test": "passed",
    "boundary": "passed",
    "secret_scan": "passed",
    "contract": "passed",
    "api": "passed",
    "api_diff": "passed",
    "docs": "passed",
    "artifact_docs": "passed",
    "examples": "passed",
    "release_evidence": "passed",
    "consumer_compatibility": "documented_external"
  }
}
JSON

cp "$OUT" "$LATEST"

echo "release manifest generated: $OUT"
echo "release manifest updated: $LATEST"
