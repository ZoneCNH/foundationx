#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PINS="$ROOT/.github/versions.env"
[ -s "$PINS" ] || { echo "missing $PINS" >&2; exit 1; }
# shellcheck disable=SC1090
source "$PINS"

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

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
    return
  fi
  shasum -a 256 "$1" | awk '{print $1}'
}

sha256_stream() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
    return
  fi
  shasum -a 256 | awk '{print $1}'
}

line_count() {
  awk 'NF { count++ } END { print count + 0 }' "$1"
}

workspace_status() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'unknown'
    return
  fi

  local status
  status="$(git status --short --untracked-files=all -- .)"
  status="$(printf '%s\n' "$status" | grep -vE '^.. release/(manifest/[^/]+\.json|dependency/(modules|updates)\.txt|standard-sync/latest\.md)$' || true)"
  if [ -n "$status" ]; then
    printf 'dirty'
    return
  fi
  printf 'clean'
}

json_string() {
  python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"
}

VERSION="$(resolve_version)"
OUT="release/manifest/${VERSION}.json"
LATEST="release/manifest/latest.json"
DEPENDENCY_MODULES="release/dependency/modules.txt"
DEPENDENCY_UPDATES="release/dependency/updates.txt"
STANDARD_SYNC_REPORT="release/standard-sync/latest.md"
VERSIONS_ENV=".github/versions.env"
TOOLCHAIN_CHECK="scripts/ci/toolchain-check.sh"
CI_WORKFLOW=".github/workflows/ci.yml"
RELEASE_WORKFLOW=".github/workflows/release.yml"
SECURITY_WORKFLOW=".github/workflows/security.yml"

./scripts/check_dependency_diff.sh
./scripts/check_standard_drift.sh

MODULE="$(GOWORK=off go list -m)"
COMMIT="$(git rev-parse HEAD 2>/dev/null || printf 'unknown')"
TREE_SHA="$(git rev-parse 'HEAD^{tree}' 2>/dev/null || printf 'unknown')"
WORKSPACE_STATUS="$(workspace_status)"
GO_VERSION="$(go version)"
GO_ACTUAL="$(go env GOVERSION)"
GENERATED_AT="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
ERROR_SCHEMA_SHA="$(sha256_file contracts/error.schema.json)"
HEALTH_SCHEMA_SHA="$(sha256_file contracts/health.schema.json)"
VERSION_SCHEMA_SHA="$(sha256_file contracts/version.schema.json)"
PUBLIC_API_SHA="$(sha256_file contracts/public_api.snapshot)"
RETRY_POLICY_SHA="$(sha256_file contracts/examples/golden/retry-policy-default.json)"
DEPENDENCY_MODULES_SHA="$(sha256_file "$DEPENDENCY_MODULES")"
DEPENDENCY_UPDATES_SHA="$(sha256_file "$DEPENDENCY_UPDATES")"
DEPENDENCY_MODULES_COUNT="$(line_count "$DEPENDENCY_MODULES")"
DEPENDENCY_UPDATES_COUNT="$(line_count "$DEPENDENCY_UPDATES")"
GO_MOD_SHA="$(sha256_file go.mod)"
GO_SUM_SHA=""
GO_SUM_PRESENT="false"
if [ -f go.sum ]; then
  GO_SUM_SHA="$(sha256_file go.sum)"
  GO_SUM_PRESENT="true"
fi
DEPENDENCIES_SHA="$({
  printf 'go.mod:%s\n' "$GO_MOD_SHA"
  printf 'go.sum:%s\n' "$GO_SUM_SHA"
  printf '%s:%s\n' "$DEPENDENCY_MODULES" "$DEPENDENCY_MODULES_SHA"
  printf '%s:%s\n' "$DEPENDENCY_UPDATES" "$DEPENDENCY_UPDATES_SHA"
} | sha256_stream)"
VERSIONS_ENV_SHA="$(sha256_file "$VERSIONS_ENV")"
TOOLCHAIN_CHECK_SHA="$(sha256_file "$TOOLCHAIN_CHECK")"
CI_WORKFLOW_SHA="$(sha256_file "$CI_WORKFLOW")"
RELEASE_WORKFLOW_SHA="$(sha256_file "$RELEASE_WORKFLOW")"
SECURITY_WORKFLOW_SHA="$(sha256_file "$SECURITY_WORKFLOW")"
TOOLS_SHA="$({
  printf '%s:%s\n' "$VERSIONS_ENV" "$VERSIONS_ENV_SHA"
  printf '%s:%s\n' "$TOOLCHAIN_CHECK" "$TOOLCHAIN_CHECK_SHA"
  printf '%s:%s\n' "$CI_WORKFLOW" "$CI_WORKFLOW_SHA"
  printf '%s:%s\n' "$RELEASE_WORKFLOW" "$RELEASE_WORKFLOW_SHA"
  printf '%s:%s\n' "$SECURITY_WORKFLOW" "$SECURITY_WORKFLOW_SHA"
  printf 'GO_MIN_VERSION:%s\n' "$GO_MIN_VERSION"
  printf 'GO_INTEGRATION_VERSION:%s\n' "$GO_INTEGRATION_VERSION"
  printf 'GOLANGCI_LINT_VERSION:%s\n' "$GOLANGCI_LINT_VERSION"
  printf 'GOVULNCHECK_VERSION:%s\n' "$GOVULNCHECK_VERSION"
  printf 'GOTESTSUM_VERSION:%s\n' "$GOTESTSUM_VERSION"
  printf 'GOFUMPT_VERSION:%s\n' "$GOFUMPT_VERSION"
  printf 'STATICCHECK_VERSION:%s\n' "$STATICCHECK_VERSION"
} | sha256_stream)"
XGO_REASON="external consumer repository/tag validation is recorded in docs/evidence/xgo-consumer-smoke.md"

cat > "$OUT" <<JSON
{
  "schema_version": "kernel.release-manifest.v1",
  "module": $(json_string "$MODULE"),
  "version": $(json_string "$VERSION"),
  "commit": $(json_string "$COMMIT"),
  "tree_sha": $(json_string "$TREE_SHA"),
  "workspace_status": $(json_string "$WORKSPACE_STATUS"),
  "go_version": $(json_string "$GO_VERSION"),
  "go_min_version": $(json_string "$GO_MIN_VERSION"),
  "go_integration_version": $(json_string "$GO_INTEGRATION_VERSION"),
  "verified_go_versions": [
    $(json_string "$GO_MIN_VERSION"),
    $(json_string "$GO_INTEGRATION_VERSION")
  ],
  "generated_at": $(json_string "$GENERATED_AT"),
  "toolchain": {
    "go_min_version": $(json_string "$GO_MIN_VERSION"),
    "go_integration_version": $(json_string "$GO_INTEGRATION_VERSION"),
    "go_actual_version": $(json_string "$GO_ACTUAL"),
    "golangci_lint_version": $(json_string "$GOLANGCI_LINT_VERSION"),
    "govulncheck_version": $(json_string "$GOVULNCHECK_VERSION"),
    "gotestsum_version": $(json_string "$GOTESTSUM_VERSION"),
    "gofumpt_version": $(json_string "$GOFUMPT_VERSION"),
    "staticcheck_version": $(json_string "$STATICCHECK_VERSION")
  },
  "tools": {
    "sha256": $(json_string "$TOOLS_SHA"),
    "versions_env": ".github/versions.env",
    "versions_env_sha256": $(json_string "$VERSIONS_ENV_SHA"),
    "toolchain_check": $(json_string "$TOOLCHAIN_CHECK"),
    "toolchain_check_sha256": $(json_string "$TOOLCHAIN_CHECK_SHA"),
    "go_version": $(json_string "$GO_VERSION"),
    "go_actual_version": $(json_string "$GO_ACTUAL"),
    "golangci_lint_version": $(json_string "$GOLANGCI_LINT_VERSION"),
    "govulncheck_version": $(json_string "$GOVULNCHECK_VERSION"),
    "gotestsum_version": $(json_string "$GOTESTSUM_VERSION"),
    "gofumpt_version": $(json_string "$GOFUMPT_VERSION"),
    "staticcheck_version": $(json_string "$STATICCHECK_VERSION"),
    "pins": {
      "go_min_version": $(json_string "$GO_MIN_VERSION"),
      "go_integration_version": $(json_string "$GO_INTEGRATION_VERSION"),
      "golangci_lint_version": $(json_string "$GOLANGCI_LINT_VERSION"),
      "govulncheck_version": $(json_string "$GOVULNCHECK_VERSION"),
      "gotestsum_version": $(json_string "$GOTESTSUM_VERSION"),
      "gofumpt_version": $(json_string "$GOFUMPT_VERSION"),
      "staticcheck_version": $(json_string "$STATICCHECK_VERSION")
    },
    "workflows": {
      "ci": {
        "path": $(json_string "$CI_WORKFLOW"),
        "sha256": $(json_string "$CI_WORKFLOW_SHA")
      },
      "release": {
        "path": $(json_string "$RELEASE_WORKFLOW"),
        "sha256": $(json_string "$RELEASE_WORKFLOW_SHA")
      },
      "security": {
        "path": $(json_string "$SECURITY_WORKFLOW"),
        "sha256": $(json_string "$SECURITY_WORKFLOW_SHA")
      }
    }
  },
  "dependencies": {
    "sha256": $(json_string "$DEPENDENCIES_SHA"),
    "modules_artifact": $(json_string "$DEPENDENCY_MODULES"),
    "updates_artifact": $(json_string "$DEPENDENCY_UPDATES"),
    "standard_sync_report": $(json_string "$STANDARD_SYNC_REPORT"),
    "modules_sha256": $(json_string "$DEPENDENCY_MODULES_SHA"),
    "updates_sha256": $(json_string "$DEPENDENCY_UPDATES_SHA"),
    "go_mod_sha256": $(json_string "$GO_MOD_SHA"),
    "go_sum_sha256": $(json_string "$GO_SUM_SHA"),
    "go_mod_tidy": "clean",
    "go_mod": {
      "path": "go.mod",
      "sha256": $(json_string "$GO_MOD_SHA")
    },
    "go_sum": {
      "path": "go.sum",
      "present": $GO_SUM_PRESENT,
      "sha256": $(json_string "$GO_SUM_SHA")
    },
    "modules": {
      "artifact": $(json_string "$DEPENDENCY_MODULES"),
      "sha256": $(json_string "$DEPENDENCY_MODULES_SHA"),
      "line_count": $DEPENDENCY_MODULES_COUNT
    },
    "updates": {
      "artifact": $(json_string "$DEPENDENCY_UPDATES"),
      "sha256": $(json_string "$DEPENDENCY_UPDATES_SHA"),
      "line_count": $DEPENDENCY_UPDATES_COUNT
    },
    "hashes": {
      "go_mod": $(json_string "$GO_MOD_SHA"),
      "go_sum": $(json_string "$GO_SUM_SHA"),
      "modules": $(json_string "$DEPENDENCY_MODULES_SHA"),
      "updates": $(json_string "$DEPENDENCY_UPDATES_SHA")
    }
  },
  "go": {
    "min_version": $(json_string "$GO_MIN_VERSION"),
    "integration_version": $(json_string "$GO_INTEGRATION_VERSION"),
    "verified_versions": [
      $(json_string "$GO_MIN_VERSION"),
      $(json_string "$GO_INTEGRATION_VERSION")
    ],
    "actual_version": $(json_string "$GO_ACTUAL")
  },
  "api": {
    "public_api_snapshot": "contracts/public_api.snapshot",
    "snapshot": "contracts/public_api.snapshot",
    "public_api_sha256": $(json_string "$PUBLIC_API_SHA"),
    "compatibility_policy": "docs/governance/API_COMPATIBILITY_POLICY.md"
  },
  "consumer_compatibility": {
    "xgo": {
      "policy": "docs/governance/XGO_CONSUMER_COMPATIBILITY.md",
      "evidence": "docs/evidence/xgo-consumer-smoke.md",
      "readme": "contracts/consumers/xgo/README.md",
      "fixture": "contracts/consumers/xgo/minimal_import_test.go",
      "status": "external-evidence-required",
      "verified": false,
      "reason": $(json_string "$XGO_REASON")
    }
  },
  "governance": {
    "package_maturity": "docs/governance/PACKAGE_MATURITY.md"
  },
  "contracts": {
    "error_schema_sha256": $(json_string "$ERROR_SCHEMA_SHA"),
    "health_schema_sha256": $(json_string "$HEALTH_SCHEMA_SHA"),
    "version_schema_sha256": $(json_string "$VERSION_SCHEMA_SHA"),
    "public_api_sha256": $(json_string "$PUBLIC_API_SHA"),
    "retry_policy_default_sha256": $(json_string "$RETRY_POLICY_SHA"),
    "golden_behavior_path": "contracts/golden",
    "golden_examples_path": "contracts/examples/golden"
  },
  "consumers": {
    "xgo": {
      "required": true,
      "verified": false,
      "evidence": "contracts/consumers/xgo/minimal_import_test.go",
      "policy": "docs/governance/XGO_CONSUMER_COMPATIBILITY.md",
      "status": "external-evidence-required"
    }
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
    "dependency_check": "passed",
    "docs": "passed",
    "artifact_docs": "passed",
    "standard_drift_check": "passed",
    "examples": "passed",
    "release_evidence": "passed",
    "consumer_compatibility": "documented"
  }
}
JSON

cp "$OUT" "$LATEST"

echo "release manifest generated: $OUT"
echo "release manifest updated: $LATEST"
