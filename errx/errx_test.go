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
		t.Fatal("nil receiver WithRetryable")
	}
	if ((*Error)(nil)).WithCode("x") != nil {
		t.Fatal("nil receiver WithCode")
	}
	if ((*Error)(nil)).WithSeverity(SeverityError) != nil {
		t.Fatal("nil receiver WithSeverity")
	}
	if ((*Error)(nil)).Unwrap() != nil {
		t.Fatal("nil receiver Unwrap")
	}
	if ((*Error)(nil)).Error() != "" {
		t.Fatal("nil receiver Error")
	}
}

func TestErrorStringVariants(t *testing.T) {
	// kind only, no op, no code
	e := NewError(ErrorKindConfig, "", "bad config")
	got := e.Error()
	want := "config: bad config"
	if got != want {
		t.Fatalf("Error() = %q, want %q", got, want)
	}
}

func TestAsErrorNoMatch(t *testing.T) {
	plain := errors.New("plain")
	_, ok := AsError(plain)
	if ok {
		t.Fatal("AsError should return false for non-Error")
	}
}

func TestIsKindNoMatch(t *testing.T) {
	plain := errors.New("plain")
	if IsKind(plain, ErrorKindTimeout) {
		t.Fatal("IsKind should return false for non-Error")
	}
	err := NewError(ErrorKindConfig, "op", "msg")
	if IsKind(err, ErrorKindTimeout) {
		t.Fatal("IsKind should return false for different kind")
	}
}
