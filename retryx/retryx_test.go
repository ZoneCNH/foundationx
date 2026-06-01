package retryx

import (
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
	p := RetryPolicy{MaxAttempts: 2, BaseDelay: 100 * time.Millisecond, MaxDelay: 150 * time.Millisecond}
	if got := p.DelayWithJitter(1, .5, 1); got != 150*time.Millisecond {
		t.Fatal(got)
	}
	if got := p.DelayWithJitter(1, .5, -1); got != 50*time.Millisecond {
		t.Fatal(got)
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
