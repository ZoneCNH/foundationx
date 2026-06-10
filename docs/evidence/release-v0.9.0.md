# Release v0.9.0 Evidence

Manifest: `release/manifest/v0.9.0.json`

## Scope

Minor release for P1 kernel governance, release evidence hardening, and current GitHub Actions pin updates.

## Summary

- Completes P1 kernel package and admission evidence for public API contracts, stdlib-only boundaries, and package boundary documents.
- Raises example regression coverage and narrows release coverage accounting to library packages.
- Hardens release preflight and evidence checks so the target version, current HEAD, manifest, and workspace state must agree.
- Updates GitHub Actions pins for current runner compatibility.
- Hosted CI is intentionally bypassed for this release because latest GitHub Actions runs fail before job steps/logs; local release gate remains required.

## Gates

| Gate | Command | Evidence |
| --- | --- | --- |
| Release preflight | `VERSION=v0.9.0 GOWORK=off make release-preflight` | Required before tag creation and used as CI bypass evidence. |
| Release final check | `VERSION=v0.9.0 GOWORK=off make release-final-check` | Included by release preflight. |
| Release evidence | `VERSION=v0.9.0 GOWORK=off make release-evidence-check` | Confirms manifest, checksums, dependency evidence, and release metadata. |
| API compatibility | `VERSION=v0.9.0 GOWORK=off make api-diff-check` | Included by CI/release gate. |
| Workflow pins | `GOWORK=off make workflow-pin-check` | Confirms workflow/action pins are current and immutable where required. |
| Race detector | `GOWORK=off go test -race ./...` | Included by CI/release gate. |
| Hosted CI | GitHub Actions | Bypassed by release owner instruction; latest hosted runs fail before job steps/logs. |

## Controlled Scope

- No non-stdlib runtime dependency introduced.
- No force-push or history rewrite required.
- Tag and release must point at a commit that has passed local release preflight.
