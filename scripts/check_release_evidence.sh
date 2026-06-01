#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

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
MANIFEST="release/manifest/${VERSION}.json"
LATEST="release/manifest/latest.json"

fail() {
  echo "ERROR: $*"
  exit 1
}

json_string() {
  local key="$1"
  sed -n "s/^[[:space:]]*\"${key}\": \"\\([^\"]*\\)\".*/\\1/p" "$MANIFEST" | head -n 1
}

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

[ -s "$MANIFEST" ] || fail "release manifest missing or empty: $MANIFEST"
[ -s "$LATEST" ] || fail "latest release manifest missing or empty: $LATEST"
cmp -s "$MANIFEST" "$LATEST" || fail "$LATEST does not match $MANIFEST"

expected_module="$(GOWORK=off go list -m)"
[ "$(json_string module)" = "$expected_module" ] || fail "manifest module does not match $expected_module"

[ "$(json_string version)" = "$VERSION" ] || fail "manifest version does not match $VERSION"

expected_commit="$(git rev-parse HEAD 2>/dev/null || printf 'unknown')"
[ "$(json_string commit)" = "$expected_commit" ] || fail "manifest commit does not match current HEAD"

expected_tree="$(git rev-parse 'HEAD^{tree}' 2>/dev/null || printf 'unknown')"
[ "$(json_string tree_sha)" = "$expected_tree" ] || fail "manifest tree_sha does not match current HEAD tree"

expected_workspace_status="$(workspace_status)"
[ "$(json_string workspace_status)" = "$expected_workspace_status" ] || fail "manifest workspace_status does not match current workspace"

[ "$(json_string error_schema_sha256)" = "$(sha256_file contracts/error.schema.json)" ] || fail "error schema hash mismatch"
[ "$(json_string health_schema_sha256)" = "$(sha256_file contracts/health.schema.json)" ] || fail "health schema hash mismatch"
[ "$(json_string version_schema_sha256)" = "$(sha256_file contracts/version.schema.json)" ] || fail "version schema hash mismatch"

for check in fmt vet unit_test race_test boundary secret_scan contract api docs artifact_docs examples; do
  grep -q "\"${check}\": \"passed\"" "$MANIFEST" || fail "manifest missing passed check: $check"
done

for artifact in \
  docs/context/CTX-GOAL-20260601-002.md \
  docs/spec/SPEC-l0-kernel-v1.0.md \
  docs/design/DESIGN-l0-kernel-v1.0.md \
  docs/adr/ADR-20260601-003-package-split.md \
  docs/adr/ADR-20260601-004-error-contract.md \
  docs/adr/ADR-20260601-005-retry-policy.md \
  docs/adr/ADR-20260601-006-observability-redaction.md \
  docs/adr/ADR-20260601-007-lifecycle-manager.md \
  docs/adr/ADR-20260601-008-health-version-contracts.md \
  docs/adr/ADR-20260601-009-contracttest-golden-examples.md \
  docs/adr/ADR-20260601-010-release-evidence-gates.md \
  docs/evidence/release-v0.1.0.md \
  docs/review/REV-GOAL-20260601-002-20260601-001.md \
  docs/retro/RETRO-20260601-002.md \
  contracts/examples/golden/README.md \
  contracts/examples/golden/error-unavailable.json \
  contracts/examples/golden/health-healthy.json \
  contracts/examples/golden/version-v0.1.0.json; do
  [ -s "$artifact" ] || fail "required goal artifact missing or empty: $artifact"
done

echo "release evidence check passed: $MANIFEST"
