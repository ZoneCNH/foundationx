package errx

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
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

func TestIsKindTraversesErrorTree(t *testing.T) {
	validation := NewError(ErrorKindValidation, "validate", "bad input")
	timeout := WrapError(ErrorKindTimeout, "call", "deadline", errors.New("driver"))
	err := errors.Join(
		fmt.Errorf("left: %w", validation),
		fmt.Errorf("right: %w", timeout),
	)

	if !IsKind(err, ErrorKindTimeout) {
		t.Fatal("IsKind should find kind in a later joined branch")
	}
	if !IsKind(fmt.Errorf("outer: %w", err), ErrorKindTimeout) {
		t.Fatal("IsKind should find kind through wrapping around a joined tree")
	}
	if IsKind(err, ErrorKindAuth) {
		t.Fatal("IsKind should not match absent kind")
	}
}

func TestErrorStringCodeWithoutOp(t *testing.T) {
	// Code is included in Error() only when Op is also set.
	e := NewError(ErrorKindInternal, "svc.Call", "something broke").WithCode("X99")
	s := e.Error()
	if !strings.Contains(s, "X99") || !strings.Contains(s, "something broke") {
		t.Fatalf("unexpected format: %s", s)
	}
	// Without Op, code is not in the string but kind and message are.
	e2 := NewError(ErrorKindInternal, "", "no op").WithCode("X99")
	s2 := e2.Error()
	if !strings.Contains(s2, "internal") || !strings.Contains(s2, "no op") {
		t.Fatalf("unexpected format: %s", s2)
	}
}

func FuzzErrorRoundtrip(f *testing.F) {
	f.Add("timeout", "op", "msg", "code", true)
	f.Add("", "", "", "", false)
	f.Add("config", "Svc.Call", "bad config", "C1", true)
	f.Add("validation", "", "invalid input", "", false)

	f.Fuzz(func(t *testing.T, kind, op, msg, code string, retryable bool) {
		e := NewError(ErrorKind(kind), op, msg).WithCode(code).WithRetryable(retryable)

		// Error() must never panic
		_ = e.Error()

		// JSON roundtrip (only valid for UTF-8 clean strings — JSON escapes non-UTF8)
		if !isASCII(kind) || !isASCII(op) || !isASCII(msg) {
			return
		}
		data, err := json.Marshal(e)
		if err != nil {
			t.Fatalf("marshal: %v", err)
		}
		var roundtrip Error
		if err := json.Unmarshal(data, &roundtrip); err != nil {
			t.Fatalf("unmarshal: %v", err)
		}
		if roundtrip.Kind != e.Kind {
			t.Fatalf("kind mismatch: %q vs %q", roundtrip.Kind, e.Kind)
		}
		if roundtrip.Op != e.Op {
			t.Fatalf("op mismatch: %q vs %q", roundtrip.Op, e.Op)
		}
		if roundtrip.Message != e.Message {
			t.Fatalf("message mismatch: %q vs %q", roundtrip.Message, e.Message)
		}
	})
}

func isASCII(s string) bool {
	for _, r := range s {
		if r > 127 {
			return false
		}
	}
	return true
}
