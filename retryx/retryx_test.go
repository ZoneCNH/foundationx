package retryx

import (
	"errors"
	"fmt"

	"github.com/ZoneCNH/kernel/errx"
	"testing"
	"time"
)

func TestDefaultRetryPolicy(t *testing.T) {
	p := DefaultRetryPolicy()
	if err := p.Validate(); err != nil {
		t.Fatal(err)
	}
	if p.MaxAttempts != 3 || p.BaseDelay != 100*time.Millisecond || p.MaxDelay != 2*time.Second {
		t.Fatal(p)
	}
}
func TestRetryPolicyValidate(t *testing.T) {
	cases := []RetryPolicy{{MaxAttempts: 0}, {MaxAttempts: 1, BaseDelay: -1}, {MaxAttempts: 1, MaxDelay: -1}, {MaxAttempts: 1, BaseDelay: 2 * time.Second, MaxDelay: time.Second}}
	for _, p := range cases {
		if !errx.IsKind(p.Validate(), errx.ErrorKindValidation) {
			t.Fatalf("%+v", p)
		}
	}
}
func TestRetryPolicyDelay(t *testing.T) {
	p := RetryPolicy{MaxAttempts: 4, BaseDelay: 100 * time.Millisecond}
	want := []time.Duration{0, 100 * time.Millisecond, 200 * time.Millisecond, 400 * time.Millisecond, 800 * time.Millisecond}
	for attempt, w := range want {
		if got := p.Delay(attempt); got != w {
			t.Fatalf("%d got %s want %s", attempt, got, w)
		}
	}
}
func TestRetryPolicyDelayMaxAndOverflow(t *testing.T) {
	p := RetryPolicy{MaxAttempts: 5, BaseDelay: 100 * time.Millisecond, MaxDelay: 250 * time.Millisecond}
	if got := p.Delay(4); got != 250*time.Millisecond {
		t.Fatal(got)
	}
	big := RetryPolicy{MaxAttempts: 2, BaseDelay: time.Duration(1 << 62)}
	if got := big.Delay(3); got != time.Duration(1<<63-1) {
		t.Fatal(got)
	}
}
func TestDelayWithJitterBounds(t *testing.T) {
	cases := []struct {
		name     string
		policy   RetryPolicy
		ratio    float64
		fraction float64
		want     time.Duration
	}{
		{
			name:     "zero base",
			policy:   RetryPolicy{MaxAttempts: 2},
			ratio:    .5,
			fraction: 1,
			want:     0,
		},
		{
			name:     "zero ratio",
			policy:   RetryPolicy{MaxAttempts: 2, BaseDelay: 100 * time.Millisecond},
			ratio:    0,
			fraction: 1,
			want:     100 * time.Millisecond,
		},
		{
			name:     "fraction lower bound",
			policy:   RetryPolicy{MaxAttempts: 2, BaseDelay: 100 * time.Millisecond},
			ratio:    .5,
			fraction: -2,
			want:     50 * time.Millisecond,
		},
		{
			name:     "fraction upper bound",
			policy:   RetryPolicy{MaxAttempts: 2, BaseDelay: 100 * time.Millisecond},
			ratio:    .5,
			fraction: 2,
			want:     150 * time.Millisecond,
		},
		{
			name:     "negative delay floor",
			policy:   RetryPolicy{MaxAttempts: 2, BaseDelay: 100 * time.Millisecond},
			ratio:    2,
			fraction: -1,
			want:     0,
		},
		{
			name:     "max delay cap",
			policy:   RetryPolicy{MaxAttempts: 2, BaseDelay: 100 * time.Millisecond, MaxDelay: 150 * time.Millisecond},
			ratio:    1,
			fraction: 1,
			want:     150 * time.Millisecond,
		},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if got := tc.policy.DelayWithJitter(1, tc.ratio, tc.fraction); got != tc.want {
				t.Fatalf("got %s want %s", got, tc.want)
			}
		})
	}
}
func TestShouldRetry(t *testing.T) {
	e := errx.NewError(errx.ErrorKindUnavailable, "op", "msg").WithRetryable(true)
	if !ShouldRetry(e) {
		t.Fatal("retryable")
	}
	if ShouldRetry(errx.NewError(errx.ErrorKindValidation, "op", "msg")) {
		t.Fatal("not retryable")
	}
}

func TestShouldRetryTraversesErrorTree(t *testing.T) {
	nonRetryable := errx.NewError(errx.ErrorKindValidation, "validate", "bad input")
	retryable := errx.NewError(errx.ErrorKindUnavailable, "call", "down").WithRetryable(true)
	err := errors.Join(
		fmt.Errorf("left: %w", nonRetryable),
		fmt.Errorf("right: %w", retryable),
	)

	if !ShouldRetry(err) {
		t.Fatal("ShouldRetry should find retryable error in a later joined branch")
	}
	if !ShouldRetry(fmt.Errorf("outer: %w", err)) {
		t.Fatal("ShouldRetry should find retryable error through wrapping around a joined tree")
	}
	if ShouldRetry(errors.Join(nonRetryable, errors.New("plain"))) {
		t.Fatal("ShouldRetry should not match when no retryable error exists")
	}
}

// ---- Benchmarks ----

func BenchmarkDelay(b *testing.B) {
	p := DefaultRetryPolicy()
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		p.Delay(3)
	}
}

func BenchmarkDelayWithJitter(b *testing.B) {
	p := DefaultRetryPolicy()
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		p.DelayWithJitter(3, 0.2, 0.5)
	}
}

func BenchmarkValidate(b *testing.B) {
	p := DefaultRetryPolicy()
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = p.Validate()
	}
}
