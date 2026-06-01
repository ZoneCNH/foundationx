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
