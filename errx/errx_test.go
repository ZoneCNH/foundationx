package errx

import (
	"encoding/json"
	"errors"
	"fmt"
	"testing"
)

func TestErrorKindMinimalSet(t *testing.T) {
	kinds := []ErrorKind{ErrorKindConfig, ErrorKindValidation, ErrorKindConnection, ErrorKindUnavailable, ErrorKindTimeout, ErrorKindAuth, ErrorKindConflict, ErrorKindRateLimit, ErrorKindCanceled, ErrorKindNotFound, ErrorKindAlreadyExist, ErrorKindInternal}
	seen := map[ErrorKind]bool{}
	for _, kind := range kinds {
		if kind == "" {
			t.Fatal("empty kind")
		}
		if seen[kind] {
			t.Fatalf("duplicate kind %q", kind)
		}
		seen[kind] = true
	}
}

func TestErrorJSONCodeSeverityRetryable(t *testing.T) {
	err := NewError(ErrorKindUnavailable, "Client.Ping", "unavailable").WithCode("DEP_DOWN").WithSeverity(SeverityError).WithRetryable(true)
	data, e := json.Marshal(err)
	if e != nil {
		t.Fatal(e)
	}
	want := `{"kind":"unavailable","code":"DEP_DOWN","severity":"error","op":"Client.Ping","message":"unavailable","retryable":true}`
	if string(data) != want {
		t.Fatalf("json = %s, want %s", data, want)
	}
}

func TestErrorWrappingAndAs(t *testing.T) {
	cause := errors.New("driver")
	err := WrapError(ErrorKindTimeout, "Client.Ping", "deadline", cause).WithRetryable(true)
	wrapped := fmt.Errorf("outer: %w", err)
	if !errors.Is(wrapped, cause) {
		t.Fatal("cause not unwrapped")
	}
	if !IsKind(wrapped, ErrorKindTimeout) {
		t.Fatal("kind not found")
	}
	got, ok := AsError(wrapped)
	if !ok || got != err {
		t.Fatal("AsError failed")
	}
}

func TestNilErrorHelpers(t *testing.T) {
	if ((*Error)(nil)).WithRetryable(true) != nil {
		t.Fatal("nil receiver")
	}
}
