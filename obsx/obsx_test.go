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
	data, _ := json.Marshal(s)
	if strings.Contains(string(data), raw) || string(data) != "\"***\"" {
		t.Fatal(string(data))
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
