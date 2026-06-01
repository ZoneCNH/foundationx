// Package contracttest 提供 L1 包复用的契约测试助手。
package contracttest

import (
	"encoding/json"
	"github.com/ZoneCNH/kernel/errx"
	"github.com/ZoneCNH/kernel/healthx"
	"testing"
)

func AssertJSONFields(t testing.TB, value any, fields ...string) {
	t.Helper()
	data, err := json.Marshal(value)
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}
	var object map[string]json.RawMessage
	if err := json.Unmarshal(data, &object); err != nil {
		t.Fatalf("unmarshal %s: %v", data, err)
	}
	for _, f := range fields {
		if _, ok := object[f]; !ok {
			t.Fatalf("missing JSON field %q in %s", f, data)
		}
	}
}
func AssertErrorKind(t testing.TB, got error, want errx.ErrorKind) {
	t.Helper()
	if !errx.IsKind(got, want) {
		t.Fatalf("error kind mismatch: %v want %s", got, want)
	}
}
func AssertHealthStatus(t testing.TB, got healthx.HealthStatus, want healthx.HealthStatusValue) {
	t.Helper()
	if got.Status != want {
		t.Fatalf("health status = %s want %s", got.Status, want)
	}
}
