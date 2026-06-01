GO ?= go
GOENV := GOWORK=off

.PHONY: fmt
fmt:
	$(GOENV) $(GO) fmt ./...

.PHONY: vet
vet:
	$(GOENV) $(GO) vet ./...

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

.PHONY: docs
docs:
	./scripts/check_docs.sh

.PHONY: examples
examples:
	$(GOENV) $(GO) run ./examples/error_kind
	$(GOENV) $(GO) run ./examples/health_checker
	$(GOENV) $(GO) run ./examples/retry_policy
	$(GOENV) $(GO) run ./examples/clock

.PHONY: evidence
evidence:
	./scripts/generate_manifest.sh

.PHONY: release-evidence-check
release-evidence-check:
	./scripts/check_release_evidence.sh

.PHONY: release-clean-check
release-clean-check:
	./scripts/check_release_clean.sh

.PHONY: ci
ci: fmt vet lint test race boundary security contracts docs examples

.PHONY: release-check
release-check:
	$(MAKE) ci
	$(MAKE) evidence
	$(MAKE) release-evidence-check

.PHONY: release-final-check
release-final-check:
	$(MAKE) release-clean-check
	$(MAKE) release-check
	$(MAKE) release-clean-check
