package contracts

import (
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

func TestReleaseCheckWiresDocumentationAndEvidenceGates(t *testing.T) {
	makefile := readRepoText(t, "Makefile")

	assertContains(t, makefile, "release-check:")
	assertContains(t, makefile, "release-clean-check:")
	assertContains(t, makefile, "release-final-check:")
	assertContains(t, makefile, "ci: fmt vet lint test race boundary security contracts api-check docs artifact-check examples")
	assertContains(t, makefile, "\t$(MAKE) release-toolchain-check")
	assertContains(t, makefile, "./scripts/ci/toolchain-check.sh")
	assertContains(t, makefile, "./scripts/ci/api-diff-check.sh")
	assertContains(t, makefile, "\t$(MAKE) ci")
	assertContains(t, makefile, "\t$(MAKE) evidence")
	assertContains(t, makefile, "\t$(MAKE) release-evidence-check")
	assertContains(t, makefile, "\t$(MAKE) toolchain-check")
	assertContains(t, makefile, "./scripts/check_docs.sh")
	assertContains(t, makefile, "./scripts/ci/api-check.sh")
	assertContains(t, makefile, "./scripts/ci/api-diff-check.sh")
	assertContains(t, makefile, "./scripts/ci/toolchain-check.sh")
	assertContains(t, makefile, "./scripts/ci/artifact-check.sh")
	assertContains(t, makefile, "./scripts/generate_manifest.sh")
	assertContains(t, makefile, "./scripts/check_release_evidence.sh")
	assertContains(t, makefile, "./scripts/check_release_clean.sh")
	assertContains(t, makefile, "lint-strict:")
	assertContains(t, makefile, "security-strict:")
}

func TestReleaseCheckRunsEvidenceAfterCIGates(t *testing.T) {
	makefile := readRepoText(t, "Makefile")
	targetBody := makeTargetBody(t, makefile, "release-check")

	toolchain := strings.Index(targetBody, "\t$(MAKE) release-toolchain-check")
	ci := strings.Index(targetBody, "\t$(MAKE) ci")
	evidence := strings.Index(targetBody, "\t$(MAKE) evidence")
	evidenceCheck := strings.Index(targetBody, "\t$(MAKE) release-evidence-check")
	if toolchain == -1 {
		t.Fatal("release-check does not run release-toolchain-check")
	}
	if ci == -1 {
		t.Fatal("release-check does not run ci")
	}
	if evidence == -1 {
		t.Fatal("release-check does not generate evidence")
	}
	if evidenceCheck == -1 {
		t.Fatal("release-check does not validate release evidence")
	}
	if toolchain >= ci || ci >= evidence || evidence >= evidenceCheck {
		t.Fatal("release-check must run toolchain, ci, evidence generation, and evidence validation in order")
	}
}

func TestReleaseFinalCheckBracketsReleaseCheckWithCleanChecks(t *testing.T) {
	makefile := readRepoText(t, "Makefile")
	targetBody := makeTargetBody(t, makefile, "release-final-check")

	firstCleanCheck := strings.Index(targetBody, "\t$(MAKE) release-clean-check")
	toolchainCheck := strings.Index(targetBody, "\t$(MAKE) release-toolchain-check")
	releaseCheck := strings.Index(targetBody, "\t$(MAKE) release-check")
	lastCleanCheck := strings.LastIndex(targetBody, "\t$(MAKE) release-clean-check")
	if firstCleanCheck == -1 || lastCleanCheck == -1 || firstCleanCheck == lastCleanCheck {
		t.Fatal("release-final-check must run release clean check before and after release-check")
	}
	if toolchainCheck == -1 {
		t.Fatal("release-final-check does not run release-toolchain-check")
	}
	if releaseCheck == -1 {
		t.Fatal("release-final-check does not run release-check")
	}
	if firstCleanCheck >= toolchainCheck || toolchainCheck >= releaseCheck || releaseCheck >= lastCleanCheck {
		t.Fatal("release-final-check must run clean check, toolchain check, release-check, then clean check")
	}
	if strings.Index(targetBody, "\t$(MAKE) lint-strict") <= releaseCheck {
		t.Fatal("release-final-check must run strict lint after release-check")
	}
	if strings.Index(targetBody, "\t$(MAKE) security-strict") <= releaseCheck {
		t.Fatal("release-final-check must run strict security after release-check")
	}
}

func TestXlibStandardAnalysisPinsReviewedGovernanceBaseline(t *testing.T) {
	analysis := readRepoText(t, filepath.Join("docs", "xlib-standard-analysis.md"))

	for _, want := range []string{
		"041a62f21428111a4b46235a7910edbdf4e07d61",
		"`contracts/` schema contract tests",
		"`scripts/check_boundary.sh`",
		"`scripts/generate_manifest.sh`",
		"`scripts/check_release_evidence.sh`",
		"CI artifact upload",
		"release workflow gate",
		"不采用 | 整仓模板覆盖",
	} {
		assertContains(t, analysis, want)
	}
}

func TestReleaseEvidenceScriptsPreserveFreshnessChecks(t *testing.T) {
	generate := readRepoText(t, filepath.Join("scripts", "generate_manifest.sh"))
	check := readRepoText(t, filepath.Join("scripts", "check_release_evidence.sh"))
	clean := readRepoText(t, filepath.Join("scripts", "check_release_clean.sh"))

	for _, want := range []string{
		"tree_sha",
		"workspace_status",
		"schema_version",
		"GO_MIN_VERSION",
		"GO_INTEGRATION_VERSION",
		"verified_go_versions",
		"error_schema_sha256",
		"health_schema_sha256",
		"version_schema_sha256",
		"PUBLIC_API_SHA",
		"schema_version",
		"kernel.release-manifest.v1",
		"GO_MIN_VERSION",
		"GO_INTEGRATION_VERSION",
		"contracts/public_api.snapshot",
		"contracts/consumers/xgo/minimal_import_test.go",
		"cp \"$OUT\" \"$LATEST\"",
	} {
		assertContains(t, generate, want)
	}

	for _, want := range []string{
		"cmp -s \"$MANIFEST\" \"$LATEST\"",
		"manifest commit does not match current HEAD",
		"manifest tree_sha does not match current HEAD tree",
		"manifest workspace_status does not match current workspace",
		"manifest schema_version mismatch",
		"manifest go_min_version does not match .github/versions.env",
		"manifest go_integration_version does not match .github/versions.env",
		"error schema hash mismatch",
		"health schema hash mismatch",
		"version schema hash mismatch",
		"public API snapshot hash mismatch",
		"manifest schema_version mismatch",
		"manifest Go min version mismatch",
		"manifest xgo consumer evidence missing",
		"release-${VERSION}.md",
	} {
		assertContains(t, check, want)
	}

	for _, want := range []string{
		"git status --short --untracked-files=all -- .",
		"grep -vE '^.. release/manifest/[^/]+\\.json$'",
		"release workspace is dirty",
	} {
		assertContains(t, clean, want)
	}
}

func TestGeneratedReleaseManifestsUseGoModModule(t *testing.T) {
	module := modulePathFromGoMod(t)
	manifests, err := filepath.Glob(filepath.Join("..", "release", "manifest", "*.json"))
	if err != nil {
		t.Fatalf("glob release manifests: %v", err)
	}
	if len(manifests) == 0 {
		t.Skip("no generated release manifests found")
	}

	for _, manifest := range manifests {
		t.Run(filepath.Base(manifest), func(t *testing.T) {
			data, err := os.ReadFile(manifest)
			if err != nil {
				t.Fatalf("read %s: %v", manifest, err)
			}

			var payload struct {
				Module string `json:"module"`
			}
			if err := json.Unmarshal(data, &payload); err != nil {
				t.Fatalf("parse %s: %v", manifest, err)
			}
			if payload.Module != module {
				t.Fatalf("%s module = %q, want %q", filepath.ToSlash(manifest), payload.Module, module)
			}
		})
	}
}

func TestReleaseCleanCheckOnlyAllowsTopLevelManifestJSON(t *testing.T) {
	clean := readRepoText(t, filepath.Join("scripts", "check_release_clean.sh"))
	const allowedManifestPattern = `^.. release/manifest/[^/]+\.json$`

	assertContains(t, clean, "grep -vE '"+allowedManifestPattern+"'")

	allowedManifest := regexp.MustCompile(allowedManifestPattern)
	for _, tc := range []struct {
		name    string
		line    string
		allowed bool
	}{
		{
			name:    "version manifest",
			line:    "?? release/manifest/v0.1.0.json",
			allowed: true,
		},
		{
			name:    "latest manifest",
			line:    " M release/manifest/latest.json",
			allowed: true,
		},
		{
			name: "non-json manifest sidecar",
			line: "?? release/manifest/not-json.txt",
		},
		{
			name: "nested manifest file",
			line: "?? release/manifest/nested/file.json",
		},
		{
			name: "ordinary tracked file",
			line: " M README.md",
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			if got := allowedManifest.MatchString(tc.line); got != tc.allowed {
				t.Fatalf("allowedManifest.MatchString(%q) = %v, want %v", tc.line, got, tc.allowed)
			}
		})
	}
}

func TestReleaseCleanCheckScriptBehavior(t *testing.T) {
	requireCommand(t, "bash")
	requireCommand(t, "git")

	script := readRepoText(t, filepath.Join("scripts", "check_release_clean.sh"))
	for _, tc := range []struct {
		name    string
		mutate  func(t *testing.T, root string)
		wantOK  bool
		wantOut string
	}{
		{
			name:   "clean worktree passes",
			mutate: func(t *testing.T, root string) {},
			wantOK: true,
		},
		{
			name: "ordinary dirty file fails",
			mutate: func(t *testing.T, root string) {
				writeTestFile(t, filepath.Join(root, "README.md"), "dirty")
			},
			wantOut: "release workspace is dirty",
		},
		{
			name: "tracked dirty file fails",
			mutate: func(t *testing.T, root string) {
				writeTestFile(t, filepath.Join(root, "tracked.txt"), "clean")
				runTestCommand(t, root, "git", "add", "tracked.txt")
				runTestCommand(t, root, "git", "commit", "-m", "add tracked file")
				writeTestFile(t, filepath.Join(root, "tracked.txt"), "dirty")
			},
			wantOut: "release workspace is dirty",
		},
		{
			name: "staged ordinary file fails",
			mutate: func(t *testing.T, root string) {
				writeTestFile(t, filepath.Join(root, "staged.txt"), "dirty")
				runTestCommand(t, root, "git", "add", "staged.txt")
			},
			wantOut: "release workspace is dirty",
		},
		{
			name: "top level generated manifest passes",
			mutate: func(t *testing.T, root string) {
				writeTestFile(t, filepath.Join(root, "release", "manifest", "v0.1.0.json"), "{}")
			},
			wantOK: true,
		},
		{
			name: "non json manifest sidecar fails",
			mutate: func(t *testing.T, root string) {
				writeTestFile(t, filepath.Join(root, "release", "manifest", "v0.1.0.txt"), "dirty")
			},
			wantOut: "release workspace is dirty",
		},
		{
			name: "nested manifest file fails",
			mutate: func(t *testing.T, root string) {
				writeTestFile(t, filepath.Join(root, "release", "manifest", "nested", "file.json"), "{}")
			},
			wantOut: "release workspace is dirty",
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			root := initReleaseCleanCheckRepo(t, script)
			tc.mutate(t, root)

			cmd := exec.Command("bash", filepath.Join(root, "scripts", "check_release_clean.sh"))
			cmd.Dir = root
			out, err := cmd.CombinedOutput()
			output := string(out)
			if tc.wantOK {
				if err != nil {
					t.Fatalf("check_release_clean.sh failed: %v\n%s", err, output)
				}
				return
			}
			if err == nil {
				t.Fatalf("check_release_clean.sh succeeded, want failure\n%s", output)
			}
			if tc.wantOut != "" && !strings.Contains(output, tc.wantOut) {
				t.Fatalf("check_release_clean.sh output = %q, want substring %q", output, tc.wantOut)
			}
		})
	}
}

func TestReleaseEvidenceScriptsResolveTagVersionConsistently(t *testing.T) {
	for _, path := range []string{
		filepath.Join("scripts", "generate_manifest.sh"),
		filepath.Join("scripts", "check_release_evidence.sh"),
	} {
		script := readRepoText(t, path)
		for _, want := range []string{
			"VERSION:-",
			"GITHUB_REF_NAME:-",
			"^v[0-9]+\\.[0-9]+\\.[0-9]+",
			"git tag --points-at HEAD --list 'v[0-9]*.[0-9]*.[0-9]*'",
			"printf 'v0.1.0'",
		} {
			assertContains(t, script, want)
		}
	}

	release := readRepoText(t, filepath.Join(".github", "workflows", "release.yml"))
	assertContains(t, release, "VERSION: ${{ github.ref_name }}")
}

func TestCIWorkflowsPreserveReleaseEvidenceGates(t *testing.T) {
	ci := readRepoText(t, filepath.Join(".github", "workflows", "ci.yml"))
	release := readRepoText(t, filepath.Join(".github", "workflows", "release.yml"))

	for _, want := range []string{
		"run: make release-toolchain-check",
		"run: make ci",
		"run: make evidence",
		"run: make release-evidence-check",
		"path: release/manifest/*.json",
	} {
		assertContains(t, ci, want)
	}

	assertContains(t, release, "run: make release-final-check")
	assertContains(t, ci, "source .github/versions.env")
	assertContains(t, release, "source .github/versions.env")
	assertContains(t, release, "path: release/manifest/*.json")
}

func TestCIToolsArePinnedWithoutBecomingLocalHardDependencies(t *testing.T) {
	makefile := readRepoText(t, "Makefile")
	ci := readRepoText(t, filepath.Join(".github", "workflows", "ci.yml"))
	release := readRepoText(t, filepath.Join(".github", "workflows", "release.yml"))
	security := readRepoText(t, filepath.Join(".github", "workflows", "security.yml"))

	versions := readRepoText(t, filepath.Join(".github", "versions.env"))
	for _, workflow := range []string{ci, release} {
		assertContains(t, workflow, "source .github/versions.env")
		assertContains(t, workflow, "go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@${GOLANGCI_LINT_VERSION}")
		assertContains(t, workflow, "go install golang.org/x/vuln/cmd/govulncheck@${GOVULNCHECK_VERSION}")
	}

	assertContains(t, security, "source .github/versions.env")
	assertContains(t, security, "go install golang.org/x/vuln/cmd/govulncheck@${GOVULNCHECK_VERSION}")
	assertContains(t, versions, "GOLANGCI_LINT_VERSION=v2.1.6")
	assertContains(t, versions, "GOVULNCHECK_VERSION=v1.3.0")
	assertContains(t, makefile, "golangci-lint not installed; skipping lint target")
	assertContains(t, makefile, "govulncheck not installed; skipping vulnerability scan")
	assertContains(t, makefile, "lint-strict:")
	assertContains(t, makefile, "security-strict:")
}

func TestSecurityWorkflowPreservesBoundaryContractGates(t *testing.T) {
	security := readRepoText(t, filepath.Join(".github", "workflows", "security.yml"))

	for _, want := range []string{
		"run: make release-toolchain-check",
		"run: make boundary",
		"run: make security",
		"run: make contracts",
	} {
		assertContains(t, security, want)
	}
}

func TestChineseReleaseDocsDescribeGeneratedEvidence(t *testing.T) {
	for _, path := range []string{"README.md", filepath.Join("docs", "release.md")} {
		text := readRepoText(t, path)
		for _, want := range []string{
			"make release-check",
			"make release-final-check",
			"release/manifest/<version>.json",
			"release/manifest/latest.json",
			"生成",
			"证据",
		} {
			assertContains(t, text, want)
		}
	}
}

func TestFormalReleaseDocsUseFinalGate(t *testing.T) {
	for _, path := range []string{
		filepath.Join(".agent", "evidence.md"),
		filepath.Join(".agent", "goal.md"),
		filepath.Join(".agent", "harness.md"),
		filepath.Join(".agent", "patch_harness.md"),
		filepath.Join(".agent", "patch_prompt.md"),
		"README.md",
		filepath.Join("docs", "goal.md"),
		filepath.Join("docs", "release.md"),
		filepath.Join("docs", "spec.md"),
		filepath.Join("docs", "testing.md"),
		filepath.Join("docs", "governance", "API_COMPATIBILITY_POLICY.md"),
		filepath.Join("docs", "governance", "PACKAGE_MATURITY.md"),
		filepath.Join("docs", "governance", "XGO_CONSUMER_COMPATIBILITY.md"),
		filepath.Join("contracts", "consumers", "xgo", "README.md"),
	} {
		text := readRepoText(t, path)
		assertContains(t, text, "make release-final-check")
	}
}

func TestDocumentationHeadingsKeepChineseContext(t *testing.T) {
	englishOnlyHeading := regexp.MustCompile(`(?m)^#{2,6}\s+[^\n\p{Han}]*[A-Za-z][^\n\p{Han}]*$`)

	for _, path := range []string{
		"README.md",
		"CHANGELOG.md",
		filepath.Join("docs", "api.md"),
		filepath.Join("docs", "design.md"),
		filepath.Join("docs", "errors.md"),
		filepath.Join("docs", "health.md"),
		filepath.Join("docs", "lifecycle.md"),
		filepath.Join("docs", "release.md"),
		filepath.Join("docs", "retry.md"),
		filepath.Join("docs", "sanitizer.md"),
		filepath.Join("docs", "spec.md"),
		filepath.Join("docs", "testing.md"),
		filepath.Join("docs", "xlib-standard-analysis.md"),
	} {
		text := readRepoText(t, path)
		if matches := englishOnlyHeading.FindAllString(text, -1); len(matches) > 0 {
			t.Fatalf("%s contains headings with English but no Chinese context: %q", path, matches)
		}
	}
}

func TestSection26ReleaseGovernanceArtifactsAreTracked(t *testing.T) {
	for _, path := range []string{
		filepath.Join(".github", "versions.env"),
		filepath.Join("scripts", "ci", "toolchain-check.sh"),
		filepath.Join("scripts", "ci", "api-diff-check.sh"),
		filepath.Join("contracts", "public_api.snapshot"),
		filepath.Join("contracts", "consumers", "xgo", "minimal_import_test.go"),
		filepath.Join("docs", "governance", "API_COMPATIBILITY_POLICY.md"),
		filepath.Join("docs", "governance", "PACKAGE_MATURITY.md"),
		filepath.Join("docs", "governance", "XGO_CONSUMER_COMPATIBILITY.md"),
		filepath.Join("docs", "governance", "RELEASE_MANIFEST_SCHEMA.md"),
		filepath.Join("contracts", "examples", "golden", "retry-policy-default.json"),
		filepath.Join("contracts", "examples", "golden", "obsx-secret-redaction.json"),
		filepath.Join("contracts", "examples", "golden", "lifecycx-rollback-order.json"),
		filepath.Join("contracts", "examples", "golden", "syncx-first-error.json"),
	} {
		text := readRepoText(t, path)
		if strings.TrimSpace(text) == "" {
			t.Fatalf("%s must not be empty", path)
		}
	}
}

func readRepoText(t *testing.T, path string) string {
	t.Helper()

	data, err := os.ReadFile(filepath.Join("..", path))
	if err != nil {
		t.Fatalf("read %s: %v", path, err)
	}
	return string(data)
}

func modulePathFromGoMod(t *testing.T) string {
	t.Helper()

	for _, line := range strings.Split(readRepoText(t, "go.mod"), "\n") {
		fields := strings.Fields(line)
		if len(fields) == 2 && fields[0] == "module" {
			return fields[1]
		}
	}
	t.Fatal("go.mod module directive not found")
	return ""
}

func makeTargetBody(t *testing.T, makefile string, target string) string {
	t.Helper()

	marker := target + ":\n"
	start := strings.Index(makefile, marker)
	if start == -1 {
		t.Fatalf("%s target not found", target)
	}

	bodyStart := start + len(marker)
	body := makefile[bodyStart:]
	if end := strings.Index(body, "\n.PHONY:"); end != -1 {
		body = body[:end]
	}
	return body
}

func initReleaseCleanCheckRepo(t *testing.T, script string) string {
	t.Helper()

	root := t.TempDir()
	writeTestFile(t, filepath.Join(root, "scripts", "check_release_clean.sh"), script)
	if err := os.Chmod(filepath.Join(root, "scripts", "check_release_clean.sh"), 0o755); err != nil {
		t.Fatalf("chmod check_release_clean.sh: %v", err)
	}

	runTestCommand(t, root, "git", "init")
	runTestCommand(t, root, "git", "config", "user.email", "contracts@example.invalid")
	runTestCommand(t, root, "git", "config", "user.name", "contracts")
	runTestCommand(t, root, "git", "add", "scripts/check_release_clean.sh")
	runTestCommand(t, root, "git", "commit", "-m", "baseline")
	return root
}

func requireCommand(t *testing.T, name string) {
	t.Helper()

	if _, err := exec.LookPath(name); err != nil {
		t.Skipf("%s not installed: %v", name, err)
	}
}

func runTestCommand(t *testing.T, dir string, name string, args ...string) {
	t.Helper()

	cmd := exec.Command(name, args...)
	cmd.Dir = dir
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("%s %s failed: %v\n%s", name, strings.Join(args, " "), err, string(out))
	}
}

func writeTestFile(t *testing.T, path string, data string) {
	t.Helper()

	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatalf("mkdir %s: %v", filepath.Dir(path), err)
	}
	if err := os.WriteFile(path, []byte(data), 0o644); err != nil {
		t.Fatalf("write %s: %v", path, err)
	}
}

func assertContains(t *testing.T, text string, want string) {
	t.Helper()

	if !strings.Contains(text, want) {
		t.Fatalf("expected text to contain %q", want)
	}
}
