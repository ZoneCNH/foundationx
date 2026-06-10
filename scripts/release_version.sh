#!/usr/bin/env bash
set -euo pipefail

release_version_error() {
  echo "ERROR: $*" >&2
  exit 1
}

require_release_version_format() {
  local version="$1"
  if ! printf '%s' "$version" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$'; then
    release_version_error "release version must match vMAJOR.MINOR.PATCH; got: ${version:-<empty>}"
  fi
}

resolve_release_version() {
  if [ -n "${VERSION:-}" ]; then
    require_release_version_format "$VERSION"
    printf '%s' "$VERSION"
    return
  fi

  if [ -n "${GITHUB_REF_NAME:-}" ] && printf '%s' "$GITHUB_REF_NAME" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$'; then
    printf '%s' "$GITHUB_REF_NAME"
    return
  fi

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local tag
    tag="$(git tag --points-at HEAD --list 'v[0-9]*.[0-9]*.[0-9]*' | sort | tail -n 1)"
    if [ -n "$tag" ]; then
      require_release_version_format "$tag"
      printf '%s' "$tag"
      return
    fi
  fi

  release_version_error "VERSION is required unless running on a semantic version tag or tagged HEAD"
}
