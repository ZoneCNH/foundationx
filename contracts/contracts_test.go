package contracts

import (
	"encoding/json"
	"os"
	"reflect"
	"sort"
	"testing"
	"time"

	"github.com/ZoneCNH/kernel/errx"
	"github.com/ZoneCNH/kernel/healthx"
	"github.com/ZoneCNH/kernel/versionx"
)

type jsonSchema struct {
	Required   []string                  `json:"required"`
	Properties map[string]schemaProperty `json:"properties"`
}

type schemaProperty struct {
	Enum []string `json:"enum"`
}

func TestErrorSchemaMatchesKernelError(t *testing.T) {
	schema := readSchema(t, "error.schema.json")
	assertStringSet(t, enumFor(t, schema, "kind"), []string{
		string(errx.ErrorKindConfig), string(errx.ErrorKindValidation), string(errx.ErrorKindConnection), string(errx.ErrorKindUnavailable), string(errx.ErrorKindTimeout), string(errx.ErrorKindAuth), string(errx.ErrorKindConflict), string(errx.ErrorKindRateLimit), string(errx.ErrorKindCanceled), string(errx.ErrorKindNotFound), string(errx.ErrorKindAlreadyExist), string(errx.ErrorKindInternal),
	})
	assertStringSet(t, enumFor(t, schema, "severity"), []string{string(errx.SeverityInfo), string(errx.SeverityWarning), string(errx.SeverityError), string(errx.SeverityCritical)})
	assertStringSet(t, schema.Required, []string{"kind", "message", "retryable"})
	err := errx.NewError(errx.ErrorKindUnavailable, "contracts.TestErrorSchemaMatchesKernelError", "not available").WithRetryable(true).WithCode("E_UNAVAILABLE").WithSeverity(errx.SeverityError)
	assertJSONKeys(t, err, []string{"kind", "code", "severity", "op", "message", "retryable"}, []string{"Kind", "Code", "Severity", "Op", "Message", "Cause", "Retryable"})
}

func TestHealthSchemaMatchesKernelHealthStatus(t *testing.T) {
	schema := readSchema(t, "health.schema.json")
	assertStringSet(t, enumFor(t, schema, "status"), []string{string(healthx.HealthHealthy), string(healthx.HealthDegraded), string(healthx.HealthUnhealthy)})
	assertStringSet(t, schema.Required, []string{"name", "status", "message", "checked_at", "latency_ms", "metadata"})
	status := healthx.NewHealthStatus("contracts", healthx.HealthHealthy, "ok", time.Unix(0, 0).UTC(), 7)
	assertJSONKeys(t, status, []string{"name", "status", "message", "checked_at", "latency_ms", "metadata"}, []string{"Name", "Status", "Message", "CheckedAt", "LatencyMs", "Metadata"})
}

func TestVersionSchemaMatchesKernelBuildInfo(t *testing.T) {
	schema := readSchema(t, "version.schema.json")
	assertStringSet(t, schema.Required, []string{"module", "version", "commit", "build_time", "go_version"})
	info := versionx.NewVersionInfo("github.com/ZoneCNH/kernel", "v0.1.0", "deadbeef", "2026-06-01T00:00:00Z", "go1.23")
	assertJSONKeys(t, info, []string{"module", "version", "commit", "build_time", "go_version"}, []string{"Module", "Version", "Commit", "BuildTime", "GoVersion"})
}

func readSchema(t *testing.T, path string) jsonSchema {
	t.Helper()
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read schema %s: %v", path, err)
	}
	var schema jsonSchema
	if err := json.Unmarshal(data, &schema); err != nil {
		t.Fatalf("parse schema %s: %v", path, err)
	}
	return schema
}
func enumFor(t *testing.T, schema jsonSchema, property string) []string {
	t.Helper()
	prop, ok := schema.Properties[property]
	if !ok {
		t.Fatalf("schema missing property %q", property)
	}
	if len(prop.Enum) == 0 {
		t.Fatalf("schema property %q has no enum", property)
	}
	return prop.Enum
}
func assertJSONKeys(t *testing.T, value any, required []string, forbidden []string) {
	t.Helper()
	data, err := json.Marshal(value)
	if err != nil {
		t.Fatalf("marshal value: %v", err)
	}
	var object map[string]json.RawMessage
	if err := json.Unmarshal(data, &object); err != nil {
		t.Fatalf("unmarshal marshaled value: %v", err)
	}
	for _, key := range required {
		if _, ok := object[key]; !ok {
			t.Fatalf("marshaled JSON missing key %q in %s", key, data)
		}
	}
	for _, key := range forbidden {
		if _, ok := object[key]; ok {
			t.Fatalf("marshaled JSON contains forbidden key %q in %s", key, data)
		}
	}
}
func assertStringSet(t *testing.T, got []string, want []string) {
	t.Helper()
	gotSorted := sortedStrings(got)
	wantSorted := sortedStrings(want)
	if !reflect.DeepEqual(gotSorted, wantSorted) {
		t.Fatalf("string set mismatch\ngot:  %v\nwant: %v", gotSorted, wantSorted)
	}
}
func sortedStrings(values []string) []string {
	sorted := append([]string(nil), values...)
	sort.Strings(sorted)
	return sorted
}
