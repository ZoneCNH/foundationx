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
}
func TestInvariant(t *testing.T) {
	if !errx.IsKind(Invariant(false, "op", "msg"), errx.ErrorKindInternal) {
		t.Fatal("kind")
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
