package contracts

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"reflect"
	"testing"

	"github.com/ZoneCNH/kernel/errx"
	"github.com/ZoneCNH/kernel/healthx"
	"github.com/ZoneCNH/kernel/lifecycx"
	"github.com/ZoneCNH/kernel/obsx"
	"github.com/ZoneCNH/kernel/retryx"
	"github.com/ZoneCNH/kernel/syncx"
	"github.com/ZoneCNH/kernel/versionx"
)

func TestGoldenBehaviorContracts(t *testing.T) {
	t.Run("errx JSON", func(t *testing.T) {
		err := errx.NewError(errx.ErrorKindUnavailable, "contracts.example", "dependency unavailable").WithRetryable(true).WithCode("example.Connect").WithSeverity(errx.SeverityError)
		assertGoldenJSON(t, "golden/error-unavailable.json", err)
		assertGoldenJSON(t, "examples/golden/error-unavailable.json", err)
	})

	t.Run("healthx JSON", func(t *testing.T) {
		status := healthx.NewHealthStatus("example", healthx.HealthHealthy, "ok", time.Date(2026, 6, 1, 0, 0, 0, 0, time.UTC), 7).WithMetadata("region", "local")
		assertGoldenJSON(t, "golden/health-healthy.json", status)
		assertGoldenJSON(t, "examples/golden/health-healthy.json", status)
	})

	t.Run("versionx JSON", func(t *testing.T) {
		info := versionx.NewVersionInfo("github.com/ZoneCNH/kernel", "v0.1.0", "local", "2026-06-01T00:00:00Z", "go1.23")
		assertGoldenJSON(t, "golden/version-v0.1.0.json", info)
		assertGoldenJSON(t, "examples/golden/version-v0.1.0.json", info)
	})

	t.Run("retryx delay behavior", func(t *testing.T) {
		policy := retryx.RetryPolicy{MaxAttempts: 3, BaseDelay: 100 * time.Millisecond, MaxDelay: time.Second}
		got := map[string]any{
			"max_attempts":  policy.MaxAttempts,
			"base_delay_ms": policy.BaseDelay.Milliseconds(),
			"max_delay_ms":  policy.MaxDelay.Milliseconds(),
			"delays_ms": []int64{
				policy.Delay(0).Milliseconds(),
				policy.Delay(1).Milliseconds(),
				policy.Delay(2).Milliseconds(),
				policy.Delay(3).Milliseconds(),
				policy.Delay(4).Milliseconds(),
				policy.Delay(5).Milliseconds(),
			},
			"jitter_ms": []int64{
				policy.DelayWithJitter(1, 0.10, -1).Milliseconds(),
				policy.DelayWithJitter(1, 0.10, 0).Milliseconds(),
				policy.DelayWithJitter(1, 0.10, 1).Milliseconds(),
			},
		}
		assertGoldenJSON(t, "golden/retry-delay-default.json", got)
	})

	t.Run("obsx secret redaction", func(t *testing.T) {
		secret := obsx.NewSecretString("secret-token")
		got := map[string]any{
			"display":  secret.String(),
			"json":     mustMarshalString(t, secret),
			"empty":    obsx.NewSecretString("").String(),
			"revealed": secret.Reveal(),
		}
		assertGoldenJSON(t, "golden/obsx-secret-redaction.json", got)
	})

	t.Run("lifecycx rollback order", func(t *testing.T) {
		var events []string
		manager := lifecycx.NewManager(
			recordingComponent{name: "a", events: &events},
			recordingComponent{name: "b", events: &events},
			recordingComponent{name: "c", events: &events, startErr: errors.New("start c")},
		)
		err := manager.Start(context.Background())
		if err == nil {
			t.Fatal("expected start error")
		}
		assertGoldenJSON(t, "golden/lifecycx-rollback-order.json", map[string]any{"error": err.Error(), "events": events})
	})

	t.Run("syncx first error aggregation", func(t *testing.T) {
		group := syncx.NewWorkerGroup(context.Background())
		canceled := make(chan bool, 1)
		group.Go(func(context.Context) error { return errors.New("first failure") })
		group.Go(func(ctx context.Context) error {
			<-ctx.Done()
			canceled <- true
			return nil
		})
		err := group.Wait()
		if err == nil {
			t.Fatal("expected worker group error")
		}
		assertGoldenJSON(t, "golden/syncx-error-aggregation.json", map[string]any{"first_error": err.Error(), "canceled_after_first_error": <-canceled})
	})
}

type recordingComponent struct {
	name     string
	events   *[]string
	startErr error
	stopErr  error
}

func (c recordingComponent) Name() string { return c.name }
func (c recordingComponent) Start(context.Context) error {
	*c.events = append(*c.events, "start:"+c.name)
	return c.startErr
}
func (c recordingComponent) Stop(context.Context) error {
	*c.events = append(*c.events, "stop:"+c.name)
	return c.stopErr
}

func assertGoldenJSON(t *testing.T, path string, value any) {
	t.Helper()
	wantData, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read golden %s: %v", path, err)
	}
	gotData, err := json.Marshal(value)
	if err != nil {
		t.Fatalf("marshal actual %s: %v", path, err)
	}
	var want any
	if err := json.Unmarshal(wantData, &want); err != nil {
		t.Fatalf("parse golden %s: %v", path, err)
	}
	var got any
	if err := json.Unmarshal(gotData, &got); err != nil {
		t.Fatalf("parse actual %s: %v", path, err)
	}
	if !reflect.DeepEqual(got, want) {
		wantPretty, _ := json.MarshalIndent(want, "", "  ")
		gotPretty, _ := json.MarshalIndent(got, "", "  ")
		t.Fatalf("golden mismatch %s\ngot:  %s\nwant: %s", path, gotPretty, wantPretty)
	}
}
