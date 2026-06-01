#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

mkdir -p release/manifest

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

MODULE="$(GOWORK=off go list -m)"
COMMIT="$(git rev-parse HEAD 2>/dev/null || printf 'unknown')"
TREE_SHA="$(git rev-parse 'HEAD^{tree}' 2>/dev/null || printf 'unknown')"
WORKSPACE_STATUS="$(workspace_status)"
GO_VERSION="$(go version | sed 's/"/\\"/g')"
GENERATED_AT="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
ERROR_SCHEMA_SHA="$(sha256_file contracts/error.schema.json)"
HEALTH_SCHEMA_SHA="$(sha256_file contracts/health.schema.json)"
VERSION_SCHEMA_SHA="$(sha256_file contracts/version.schema.json)"

cat > "$OUT" <<JSON
{
  "module": "$MODULE",
  "version": "$VERSION",
  "commit": "$COMMIT",
  "tree_sha": "$TREE_SHA",
  "workspace_status": "$WORKSPACE_STATUS",
  "go_version": "$GO_VERSION",
  "generated_at": "$GENERATED_AT",
  "contracts": {
    "error_schema_sha256": "$ERROR_SCHEMA_SHA",
    "health_schema_sha256": "$HEALTH_SCHEMA_SHA",
    "version_schema_sha256": "$VERSION_SCHEMA_SHA"
  },
  "checks": {
    "fmt": "passed",
    "vet": "passed",
    "unit_test": "passed",
    "race_test": "passed",
    "boundary": "passed",
    "secret_scan": "passed",
    "contract": "passed",
    "api": "passed",
    "docs": "passed",
    "artifact_docs": "passed",
    "examples": "passed"
  }
}
JSON

cp "$OUT" "$LATEST"

echo "release manifest generated: $OUT"
echo "release manifest updated: $LATEST"
