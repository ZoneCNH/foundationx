package validx

import (
	"github.com/ZoneCNH/kernel/errx"
	"testing"
)

func TestPrecondition(t *testing.T) {
	if Precondition(true, "op", "msg") != nil {
		t.Fatal("want nil")
	}
	if !errx.IsKind(Precondition(false, "op", "msg"), errx.ErrorKindValidation) {
		t.Fatal("kind")
	}
	// Verify Precondition produces SeverityWarning
	err := Precondition(false, "op", "msg")
	if e, ok := errx.AsError(err); !ok || e.Severity != errx.SeverityWarning {
		t.Fatalf("expected SeverityWarning, got %v", err)
	}
}
func TestInvariant(t *testing.T) {
	if !errx.IsKind(Invariant(false, "op", "msg"), errx.ErrorKindInternal) {
		t.Fatal("kind")
	}
	// Verify Invariant produces SeverityError
	err := Invariant(false, "op", "msg")
	if e, ok := errx.AsError(err); !ok || e.Severity != errx.SeverityError {
		t.Fatalf("expected SeverityError, got %v", err)
	}
}
func TestRequireNonEmpty(t *testing.T) {
	if RequireNonEmpty("op", "name", "x") != nil {
		t.Fatal("nil")
	}
	if !errx.IsKind(RequireNonEmpty("op", "name", ""), errx.ErrorKindValidation) {
		t.Fatal("kind")
	}
}
