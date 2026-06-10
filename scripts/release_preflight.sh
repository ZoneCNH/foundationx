#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# shellcheck source=scripts/release_version.sh
source "$ROOT/scripts/release_version.sh"

VERSION="$(resolve_release_version)"
require_release_version_format "$VERSION"

require_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || release_version_error "release-preflight must run inside a git worktree"
}

require_main_branch() {
  local branch
  branch="$(git rev-parse --abbrev-ref HEAD)"
  [ "$branch" = "main" ] || release_version_error "release-preflight must run on main; current branch: $branch"
}

require_clean_worktree() {
  GOWORK="${GOWORK:-off}" make release-clean-check
}

require_origin_main_head() {
  git fetch --quiet origin main --tags
  local head origin_main
  head="$(git rev-parse HEAD)"
  origin_main="$(git rev-parse origin/main)"
  [ "$head" = "$origin_main" ] || release_version_error "HEAD must match origin/main before release"
}

require_absent_tag() {
  if git rev-parse -q --verify "refs/tags/$VERSION" >/dev/null; then
    release_version_error "local tag already exists: $VERSION"
  fi

  if git ls-remote --exit-code --tags origin "refs/tags/$VERSION" >/dev/null 2>&1; then
    release_version_error "remote tag already exists: $VERSION"
  fi
}

require_changelog_entry() {
  grep -Eq "^## ${VERSION}( |$)" CHANGELOG.md || release_version_error "CHANGELOG.md is missing heading for $VERSION"
}

require_git_repo
require_main_branch
require_clean_worktree
require_origin_main_head
require_absent_tag
require_changelog_entry

VERSION="$VERSION" GOWORK="${GOWORK:-off}" make release-final-check

echo "release preflight passed: $VERSION"
