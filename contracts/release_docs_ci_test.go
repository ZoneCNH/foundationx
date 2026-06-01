package contracts

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

func TestReleaseCheckWiresDocumentationAndEvidenceGates(t *testing.T) {
	makefile := readRepoText(t, "Makefile")

	assertContains(t, makefile, "release-check: ci evidence release-evidence-check")
	assertContains(t, makefile, "ci: fmt vet lint test race boundary security contracts docs examples")
	assertContains(t, makefile, "./scripts/check_docs.sh")
	assertContains(t, makefile, "./scripts/generate_manifest.sh")
	assertContains(t, makefile, "./scripts/check_release_evidence.sh")
}

func TestBaselibTemplateAnalysisPinsReviewedGovernanceBaseline(t *testing.T) {
	analysis := readRepoText(t, filepath.Join("docs", "baselib-template-analysis.md"))

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

	for _, want := range []string{
		"tree_sha",
		"workspace_status",
		"error_schema_sha256",
		"health_schema_sha256",
		"version_schema_sha256",
		"cp \"$OUT\" \"$LATEST\"",
	} {
		assertContains(t, generate, want)
	}

	for _, want := range []string{
		"cmp -s \"$MANIFEST\" \"$LATEST\"",
		"manifest commit does not match current HEAD",
		"manifest tree_sha does not match current HEAD tree",
		"manifest workspace_status does not match current workspace",
		"error schema hash mismatch",
		"health schema hash mismatch",
		"version schema hash mismatch",
	} {
		assertContains(t, check, want)
	}
}

func TestCIWorkflowsPreserveReleaseEvidenceGates(t *testing.T) {
	ci := readRepoText(t, filepath.Join(".github", "workflows", "ci.yml"))
	release := readRepoText(t, filepath.Join(".github", "workflows", "release.yml"))

	for _, want := range []string{
		"run: make ci",
		"run: make evidence",
		"run: make release-evidence-check",
		"path: release/manifest/*.json",
	} {
		assertContains(t, ci, want)
	}

	assertContains(t, release, "run: make release-check")
	assertContains(t, release, "path: release/manifest/*.json")
}

func TestCIToolsArePinnedWithoutBecomingLocalHardDependencies(t *testing.T) {
	makefile := readRepoText(t, "Makefile")
	ci := readRepoText(t, filepath.Join(".github", "workflows", "ci.yml"))
	release := readRepoText(t, filepath.Join(".github", "workflows", "release.yml"))
	security := readRepoText(t, filepath.Join(".github", "workflows", "security.yml"))

	for _, workflow := range []string{ci, release} {
		assertContains(t, workflow, "go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.1.6")
		assertContains(t, workflow, "go install golang.org/x/vuln/cmd/govulncheck@v1.1.4")
	}

	assertContains(t, security, "go install golang.org/x/vuln/cmd/govulncheck@v1.1.4")
	assertContains(t, makefile, "golangci-lint not installed; skipping lint target")
	assertContains(t, makefile, "govulncheck not installed; skipping vulnerability scan")
}

func TestSecurityWorkflowPreservesBoundaryContractGates(t *testing.T) {
	security := readRepoText(t, filepath.Join(".github", "workflows", "security.yml"))

	for _, want := range []string{
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
			"release/manifest/v0.1.0.json",
			"release/manifest/latest.json",
			"生成",
			"证据",
		} {
			assertContains(t, text, want)
		}
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
		filepath.Join("docs", "baselib-template-analysis.md"),
	} {
		text := readRepoText(t, path)
		if matches := englishOnlyHeading.FindAllString(text, -1); len(matches) > 0 {
			t.Fatalf("%s contains headings with English but no Chinese context: %q", path, matches)
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

func assertContains(t *testing.T, text string, want string) {
	t.Helper()

	if !strings.Contains(text, want) {
		t.Fatalf("expected text to contain %q", want)
	}
}
