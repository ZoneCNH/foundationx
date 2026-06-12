GO ?= go
GOENV := GOWORK=off
COVERAGE_THRESHOLD ?= 100
BENCH_REGRESSION_THRESHOLD ?= 25

.PHONY: fmt
fmt:
	$(GOENV) $(GO) fmt ./...

.PHONY: vet
vet:
	$(GOENV) $(GO) vet ./...

.PHONY: toolchain-check
toolchain-check:
	$(GOENV) ./scripts/ci/toolchain-check.sh

.PHONY: release-toolchain-check
release-toolchain-check:
	$(GOENV) ./scripts/ci/toolchain-check.sh --strict

.PHONY: lint
lint:
	@if ! command -v golangci-lint >/dev/null 2>&1; then \
		echo "golangci-lint not installed; install the version pinned in .github/versions.env"; \
		exit 1; \
	fi
	$(GOENV) golangci-lint run ./...

.PHONY: lint-strict
lint-strict:
	$(GOENV) golangci-lint run ./...

.PHONY: test
test:
	$(GOENV) $(GO) test -count=1 $$($(GOENV) $(GO) list ./... | grep -v /examples | grep -v /scripts)

.PHONY: coverage-threshold
coverage-threshold:
	@pkgs=$$($(GOENV) $(GO) list ./... | grep -v /examples | grep -v /scripts); \
		tmp=$$(mktemp); \
		trap 'rm -f "$$tmp"' EXIT HUP INT TERM; \
		if ! $(GOENV) $(GO) test -count=1 -coverprofile=coverage.out $$pkgs >"$$tmp" 2>&1; then \
			cat "$$tmp" >&2; \
			exit 1; \
		fi; \
		cat "$$tmp" >&2; \
		awk -v threshold="$(COVERAGE_THRESHOLD)" '/coverage: \[no statements\]/{ next } /coverage:/{ split($$2, a, "/"); pkg=a[length(a)]; sub(/.*coverage: /, ""); sub(/% of.*/, ""); if ($$1+0 < threshold) { printf "FAIL: %s coverage %s%% < %s%%\n", pkg, $$1, threshold; fail=1 } } END { if (fail) exit 1 }' "$$tmp"
	@echo "All packages meet $(COVERAGE_THRESHOLD)% coverage threshold."

.PHONY: workflow-pin-check
workflow-pin-check:
	./scripts/ci/workflow-pin-check.sh

.PHONY: race
race:
	$(GOENV) $(GO) test -race -count=1 $$($(GOENV) $(GO) list ./... | grep -v /examples | grep -v /scripts)

.PHONY: cover
cover:
	@pkgs=$$($(GOENV) $(GO) list ./... | grep -v /examples | grep -v /scripts); \
	$(GOENV) $(GO) test -count=1 -coverprofile=coverage.out $$pkgs

.PHONY: boundary
boundary:
	./scripts/check_boundary.sh

.PHONY: security
security:
	@if ! command -v govulncheck >/dev/null 2>&1; then \
		echo "govulncheck not installed; install the version pinned in .github/versions.env"; \
		exit 1; \
	fi
	$(GOENV) govulncheck ./...
	./scripts/check_secrets.sh
	@if command -v gosec >/dev/null 2>&1; then \
		echo "running gosec..."; \
		$(GOENV) gosec -quiet ./...; \
	else \
		echo "gosec not installed; skipping (install: go install github.com/securego/gosec/v2/cmd/gosec@latest)"; \
	fi

.PHONY: security-strict
security-strict:
	$(GOENV) govulncheck ./...
	./scripts/check_secrets.sh
	@if ! command -v gosec >/dev/null 2>&1; then \
		echo "gosec not installed; install the version pinned in .github/versions.env"; \
		exit 1; \
	fi
	$(GOENV) gosec -quiet ./...


.PHONY: bench
bench:
	@pkgs=$$($(GOENV) $(GO) list ./... | grep -v /examples | grep -v /scripts | grep -v /contracts); \
	for pkg in $$pkgs; do \
		$(GOENV) $(GO) test -bench=. -benchmem -count=1 $$pkg 2>/dev/null || true; \
	done

.PHONY: bench-check
bench-check:
	./scripts/ci/bench-check.sh

.PHONY: bench-baseline
bench-baseline:
	@rm -f contracts/bench/baseline.txt
	./scripts/ci/bench-check.sh

.PHONY: contracts
contracts:
	./scripts/check_contracts.sh

.PHONY: api-check
api-check:
	./scripts/ci/api-check.sh
	./scripts/ci/api-diff-check.sh

.PHONY: api-diff-check
api-diff-check:
	./scripts/ci/api-diff-check.sh

.PHONY: docs
docs:
	./scripts/check_docs.sh

.PHONY: artifact-check
artifact-check:
	./scripts/ci/artifact-check.sh

.PHONY: dependency-check
dependency-check:
	./scripts/check_dependency_diff.sh

.PHONY: standard-drift-check
standard-drift-check:
	./scripts/check_standard_drift.sh

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
	$(GOENV) $(GO) run ./examples/context
	$(GOENV) $(GO) run ./examples/shutdown

.PHONY: evidence
evidence:
	./scripts/generate_manifest.sh

.PHONY: release-evidence-check
release-evidence-check:
	./scripts/check_release_evidence.sh

.PHONY: release-clean-check
release-clean-check:
	./scripts/check_release_clean.sh

.PHONY: all
all: ci

.PHONY: ci
ci: fmt vet lint test coverage-threshold race bench-check boundary security contracts api-check docs artifact-check dependency-check standard-drift-check workflow-pin-check examples

.PHONY: release-check
release-check:
	$(MAKE) toolchain-check
	$(MAKE) ci
	$(MAKE) evidence
	$(MAKE) release-evidence-check

.PHONY: release-final-check
release-final-check:
	$(MAKE) release-clean-check
	$(MAKE) release-toolchain-check
	$(MAKE) release-check
	$(MAKE) lint-strict
	$(MAKE) security-strict
	$(MAKE) release-clean-check

.PHONY: docs-check
docs-check: docs artifact-check standard-drift-check

.PHONY: boundary-check
boundary-check: boundary

.PHONY: evidence-check
evidence-check: evidence release-evidence-check

.PHONY: release-preflight
release-preflight:
	./scripts/release_preflight.sh

.PHONY: primitive-check
primitive-check:
	./scripts/ci/primitive-check.sh

.PHONY: kernel-admission-check
kernel-admission-check:
	./scripts/ci/kernel-admission-check.sh
