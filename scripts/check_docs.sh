#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

require_file() {
  local path="$1"
  [ -f "$path" ] || fail "required documentation or governance file missing: $path"
}

require_dir() {
  local path="$1"
  [ -d "$path" ] || fail "required package directory missing: $path"
}

require_text() {
  local path="$1"
  local needle="$2"
  require_file "$path"
  grep -Fq "$needle" "$path" || fail "$path does not mention required text: $needle"
}

require_ignored() {
  local path="$1"
  git check-ignore -q "$path" || fail "$path must be ignored as generated release evidence"
}

required_files=(
  README.md
  docs/goal.md
  docs/spec.md
  docs/design.md
  docs/api.md
  docs/release.md
  docs/downstream-sync-policy.md
  docs/standard/README.md
  docs/standard/xlib-standard.md
  docs/standard/layering.md
  docs/standard/module-boundary.md
  docs/standard/harness-gates.md
  docs/standard/release-standard.md
  docs/standard/security-and-secret-policy.md
  docs/standard/evidence-protocol.md
  docs/standard/docker-toolchain-standard.md
  docs/standard/downstream-compatibility.md
  docs/standard/goalcli-cli-contract.md
  docs/standard/template-generation-contract.md
  docs/governance/API_COMPATIBILITY_POLICY.md
  docs/governance/PACKAGE_MATURITY.md
  docs/governance/RELEASE_MANIFEST_SCHEMA.md
  docs/governance/XGO_CONSUMER_COMPATIBILITY.md
  docs/evidence/dependency-automation.md
  docs/evidence/xgo-consumer-smoke.md
  release/manifest/template.json
  contracts/public_api.snapshot
  contracts/error.schema.json
  contracts/health.schema.json
  contracts/version.schema.json
  .github/workflows/ci.yml
  .github/workflows/release.yml
  .github/workflows/security.yml
  .github/dependabot.yml
  renovate.json
  Makefile
  .gitignore
  scripts/generate_manifest.sh
  scripts/check_release_evidence.sh
  scripts/check_dependency_diff.sh
  scripts/check_standard_drift.sh
  scripts/ci/api-check.sh
  scripts/ci/api-diff-check.sh
  scripts/ci/artifact-check.sh
  scripts/ci/kernel-admission-check.sh
  scripts/ci/primitive-check.sh
)

for path in "${required_files[@]}"; do
  require_file "$path"
done

packages=(
  contextx
  contracttest
  errx
  healthx
  lifecycx
  obsx
  retryx
  shutdownx
  syncx
  timex
  validx
  versionx
)

for pkg in "${packages[@]}"; do
  require_dir "$pkg"
  require_file "$pkg/README.md"
  require_file "docs/$pkg.md"
  require_text "docs/$pkg.md" "$pkg"
done

require_text README.md "github.com/ZoneCNH/kernel"
require_text README.md "L0"
require_text README.md "Go 标准库"
require_text README.md "make docs-check"
require_text README.md "make release-check"
require_text README.md "make release-final-check"
require_text README.md "release/manifest/latest.json"
require_text README.md "docs/standard/"

require_text docs/goal.md "github.com/ZoneCNH/kernel"
require_text docs/goal.md "标准库"
require_text docs/spec.md "L0"
require_text docs/design.md "避免供应商绑定"
require_text docs/api.md "API 参考文档"
require_text docs/release.md "release/manifest/latest.json"

require_text docs/downstream-sync-policy.md "kernel"
require_text docs/downstream-sync-policy.md "corekit"
require_text docs/downstream-sync-policy.md "downstream_sync_required"
require_text docs/downstream-sync-policy.md "downstream_release_decision"
require_text docs/downstream-sync-policy.md "repository_rules_release_decision"

require_text docs/standard/README.md "xlib-standard"
require_text docs/standard/README.md "kernel"
require_text docs/standard/layering.md "L0"
require_text docs/standard/module-boundary.md "\`kernel\` 禁止内容"
require_text docs/standard/harness-gates.md "docs-check"
require_text docs/standard/release-standard.md "release/manifest/latest.json"
require_text docs/standard/security-and-secret-policy.md "check_secrets.sh"
require_text docs/standard/evidence-protocol.md "release/manifest/latest.json.sha256"

require_text docs/standard/docker-toolchain-standard.md "GOWORK=off"
require_text docs/standard/downstream-compatibility.md "kernel"
require_text docs/standard/goalcli-cli-contract.md "goalcli"
require_text docs/standard/template-generation-contract.md "goalcli"

require_text docs/governance/API_COMPATIBILITY_POLICY.md "public_api.snapshot"
require_text docs/governance/PACKAGE_MATURITY.md "Package Maturity"
require_text docs/governance/RELEASE_MANIFEST_SCHEMA.md "downstream_sync_required"
require_text docs/governance/XGO_CONSUMER_COMPATIBILITY.md "xgo_external_verified"

require_text release/manifest/template.json '"dependencies"'
require_text release/manifest/template.json '"standard_impact"'
require_text release/manifest/template.json '"downstream_sync_required"'
require_text release/manifest/template.json '"generator_evidence"'
require_text release/manifest/template.json '"dependency_check"'

require_text Makefile "docs-check"
require_text Makefile "dependency-check"
require_text Makefile "api-diff-check"
require_text Makefile "release-check"

require_text .github/workflows/ci.yml "make ci"
require_text .github/workflows/ci.yml "make release-evidence-check"
require_text .github/workflows/release.yml "release/manifest/*.json"
require_text .github/workflows/release.yml "release/manifest/*.json.sha256"
require_text .github/workflows/security.yml "make security"

require_text scripts/generate_manifest.sh "run_release_gates"
require_text scripts/check_release_evidence.sh "release_evidence_check"
require_text scripts/ci/api-diff-check.sh "publicStructExpr"

require_ignored release/manifest/latest.json
require_ignored release/manifest/latest.json.sha256

echo "docs check passed"
