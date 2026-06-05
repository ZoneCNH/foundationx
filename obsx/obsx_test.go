package obsx

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"testing"
)

func TestNoopInterfaces(t *testing.T) {
	var _ Logger = NoopLogger{}
	var _ Metrics = NoopMetrics{}
	var _ Tracer = NoopTracer{}
	ctx, span := NoopTracer{}.Start(context.Background(), "op", Field{Key: "k", Value: "v"})
	if ctx == nil || span == nil {
		t.Fatal("nil")
	}
	span.SetFields()
	span.RecordError(nil)
	span.End()
	NoopLogger{}.Info(ctx, "msg")
	NoopMetrics{}.Count(ctx, "n", 1)
}
func TestSecretStringMasks(t *testing.T) {
	raw := "super-secret"
	s := NewSecretString(raw)
	if fmt.Sprint(s) != "***" || s.Sanitize() != "***" || s.Reveal() != raw {
		t.Fatal(s)
	}
	if s.GoString() != "***" {
		t.Fatalf("GoString() = %q", s.GoString())
	}
	data, _ := json.Marshal(s)
	if strings.Contains(string(data), raw) || string(data) != "\"***\"" {
		t.Fatal(string(data))
	}
}

func TestSecretStringFormatDoesNotRevealRawValue(t *testing.T) {
	raw := "super-secret"
	s := NewSecretString(raw)
	formats := []string{"%v", "%+v", "%#v", "%s", "%q", "%12s", "%.2s"}
	for _, format := range formats {
		t.Run(format, func(t *testing.T) {
			got := fmt.Sprintf(format, s)
			if strings.Contains(got, raw) {
				t.Fatalf("format %s revealed raw value: %q", format, got)
			}
			if !strings.Contains(got, "***") && format != "%.2s" {
				t.Fatalf("format %s did not include masked value: %q", format, got)
			}
		})
	}
}

func TestSecretStringEmpty(t *testing.T) {
	s := NewSecretString("")
	if !s.IsZero() || s.String() != "" {
		t.Fatal("empty")
	}
	data, _ := json.Marshal(s)
	if string(data) != "\"\"" {
		t.Fatal(string(data))
	}
}

func TestSecretStringRevealEmpty(t *testing.T) {
	var s SecretString
	if s.Reveal() != "" {
		t.Fatalf("expected empty, got %q", s.Reveal())
	}
}
