package foundationx

import (
	"testing"
	"time"
)

func TestDefaultRetryPolicyValid(t *testing.T) {
	policy := DefaultRetryPolicy()

	if err := policy.Validate(); err != nil {
		t.Fatalf("Validate() error = %v", err)
	}
	if policy.MaxAttempts != 3 {
		t.Fatalf("MaxAttempts = %d, want 3", policy.MaxAttempts)
	}
	if policy.BaseDelay != 100*time.Millisecond {
		t.Fatalf("BaseDelay = %s, want 100ms", policy.BaseDelay)
	}
	if policy.MaxDelay != 2*time.Second {
		t.Fatalf("MaxDelay = %s, want 2s", policy.MaxDelay)
	}
}

func TestRetryPolicyValidateInvalidMaxAttempts(t *testing.T) {
	err := (RetryPolicy{MaxAttempts: 0}).Validate()

	if !IsKind(err, ErrorKindValidation) {
		t.Fatalf("Validate() error = %v, want validation kind", err)
	}
}

func TestRetryPolicyValidateInvalidBaseDelay(t *testing.T) {
	err := (RetryPolicy{MaxAttempts: 1, BaseDelay: -time.Nanosecond}).Validate()

	if !IsKind(err, ErrorKindValidation) {
		t.Fatalf("Validate() error = %v, want validation kind", err)
	}
}

func TestRetryPolicyValidateInvalidMaxDelay(t *testing.T) {
	err := (RetryPolicy{MaxAttempts: 1, MaxDelay: -time.Nanosecond}).Validate()

	if !IsKind(err, ErrorKindValidation) {
		t.Fatalf("Validate() error = %v, want validation kind", err)
	}
}

func TestRetryPolicyValidateBaseDelayExceedsMaxDelay(t *testing.T) {
	err := (RetryPolicy{
		MaxAttempts: 1,
		BaseDelay:   2 * time.Second,
		MaxDelay:    time.Second,
	}).Validate()

	if !IsKind(err, ErrorKindValidation) {
		t.Fatalf("Validate() error = %v, want validation kind", err)
	}
}

func TestRetryPolicyDelayExponential(t *testing.T) {
	policy := RetryPolicy{
		MaxAttempts: 4,
		BaseDelay:   100 * time.Millisecond,
		MaxDelay:    0,
	}

	tests := []struct {
		attempt int
		want    time.Duration
	}{
		{attempt: 0, want: 0},
		{attempt: 1, want: 100 * time.Millisecond},
		{attempt: 2, want: 200 * time.Millisecond},
		{attempt: 3, want: 400 * time.Millisecond},
		{attempt: 4, want: 800 * time.Millisecond},
	}

	for _, tt := range tests {
		if got := policy.Delay(tt.attempt); got != tt.want {
			t.Fatalf("Delay(%d) = %s, want %s", tt.attempt, got, tt.want)
		}
	}
}

func TestRetryPolicyDelayMaxDelay(t *testing.T) {
	policy := RetryPolicy{
		MaxAttempts: 5,
		BaseDelay:   100 * time.Millisecond,
		MaxDelay:    250 * time.Millisecond,
	}

	if got := policy.Delay(4); got != 250*time.Millisecond {
		t.Fatalf("Delay(4) = %s, want 250ms", got)
	}
}

func TestRetryPolicyDelaySaturatesOnOverflow(t *testing.T) {
	policy := RetryPolicy{
		MaxAttempts: 2,
		BaseDelay:   time.Duration(1 << 62),
		MaxDelay:    0,
	}

	if got := policy.Delay(3); got != time.Duration(1<<63-1) {
		t.Fatalf("Delay(3) = %s, want max duration", got)
	}
}
