# Release v0.8.1 Evidence

Manifest: `release/manifest/v0.8.1.json`

## Scope

Patch release candidate for `syncx` cancellation accounting and release gate hardening.

## Summary

- `syncx.Group.Acquire` cancellation-before-acquire behavior remains covered by regression tests from the current release branch.
- `release-preflight` now enforces release branch state before tag creation: clean `main`, `HEAD == origin/main`, absent local/remote target tag, and a matching `CHANGELOG.md` heading.
- Release manifest and evidence checks now require an explicit semantic version source instead of silently falling back to `v0.1.0`.
- Documentation now matches the enforced release flow.

## Gates

| Gate | Expected command | Evidence |
| --- | --- | --- |
| Full CI | `VERSION=v0.8.1 make ci` | Required before release. |
| Release evidence | `VERSION=v0.8.1 make release-evidence-check` | Confirms manifest, checksums, required evidence docs, and tool pins. |
| Release final check | `VERSION=v0.8.1 make release-final-check` | Required on a clean worktree before release. |
| Release preflight | `VERSION=v0.8.1 make release-preflight` | Required on clean `main` with `HEAD == origin/main` before tag creation. |
| API compatibility | `VERSION=v0.8.1 make api-diff-check` | Confirms exported API stays compatible with the latest released tag. |
| Coverage | `VERSION=v0.8.1 make coverage-threshold` | Enforces package coverage threshold for library packages. |
| Workflow pins | `VERSION=v0.8.1 make workflow-pin-check` | Confirms GitHub Actions/tool pins stay aligned with `.github/versions.env`. |
| Race detector | `GOWORK=off go test -race ./...` | Required because this patch validates concurrency behavior. |
| Vet | `GOWORK=off go vet ./...` | Required by release final check. |

## Controlled Scope

- No non-stdlib runtime dependency is introduced.
- No public API expansion is required for this patch release.
- Release automation changes are limited to preflight/version evidence generation scripts and their documented contract.
