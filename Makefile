GO ?= go
GOENV := GOWORK=off

.PHONY: fmt
fmt:
	$(GOENV) $(GO) fmt ./...

.PHONY: vet
vet:
	$(GOENV) $(GO) vet ./...

.PHONY: toolchain-check
toolchain-check:
	./scripts/ci/toolchain-check.sh --strict

.PHONY: lint
lint:
	@if command -v golangci-lint >/dev/null 2>&1; then \
		$(GOENV) golangci-lint run ./...; \
	else \
		echo "golangci-lint not installed; skipping lint target"; \
	fi

.PHONY: test
test:
	$(GOENV) $(GO) test ./...

.PHONY: race
race:
	$(GOENV) $(GO) test -race ./...

.PHONY: cover
cover:
	$(GOENV) $(GO) test -coverprofile=coverage.out ./...

.PHONY: boundary
boundary:
	./scripts/check_boundary.sh

.PHONY: security
security:
	@if command -v govulncheck >/dev/null 2>&1; then \
		$(GOENV) govulncheck ./...; \
	else \
		echo "govulncheck not installed; skipping vulnerability scan"; \
	fi
	./scripts/check_secrets.sh

.PHONY: contracts
contracts:
	./scripts/check_contracts.sh

.PHONY: api-diff-check
api-diff-check:
	./scripts/ci/api-diff-check.sh

.PHONY: api-check
api-check:
	./scripts/ci/api-check.sh
	$(MAKE) api-diff-check

.PHONY: api-diff-check
api-diff-check:
	./scripts/ci/api-diff-check.sh

.PHONY: docs
docs:
	./scripts/check_docs.sh

.PHONY: artifact-check
artifact-check:
	./scripts/ci/artifact-check.sh

.PHONY: examples
examples:
	$(GOENV) $(GO) run ./examples/error_kind
	$(GOENV) $(GO) run ./examples/health_checker
	$(GOENV) $(GO) run ./examples/retry_policy
	$(GOENV) $(GO) run ./examples/clock
	$(GOENV) $(GO) run ./examples/lifecycle
	$(GOENV) $(GO) run ./examples/observability
	$(GOENV) $(GO) run ./examples/validation
	$(GOENV) $(GO) run ./examples/sync_group
	$(GOENV) $(GO) run ./examples/version_info
	$(GOENV) $(GO) run ./examples/contract_helper


.PHONY: evidence
evidence:
	./scripts/generate_manifest.sh

.PHONY: release-evidence-check
release-evidence-check:
	./scripts/check_release_evidence.sh

.PHONY: release-toolchain-check
release-toolchain-check:
	./scripts/ci/toolchain-check.sh

.PHONY: release-clean-check
release-clean-check:
	./scripts/check_release_clean.sh

.PHONY: ci
ci: fmt vet lint test race boundary security contracts api-check docs artifact-check examples

.PHONY: release-check
release-check:
	$(MAKE) release-toolchain-check
	$(MAKE) ci
	$(MAKE) evidence
	$(MAKE) release-evidence-check

.PHONY: release-final-check
release-final-check:
	$(MAKE) release-clean-check
	$(MAKE) release-toolchain-check
	$(MAKE) release-check
	$(MAKE) release-clean-check

.PHONY: docs-check
docs-check: docs artifact-check

.PHONY: boundary-check
boundary-check: boundary

.PHONY: evidence-check
evidence-check: evidence release-evidence-check

.PHONY: release-preflight
release-preflight: release-final-check
