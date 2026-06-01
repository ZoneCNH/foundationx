package contracts

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"reflect"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/ZoneCNH/kernel/lifecycx"
	"github.com/ZoneCNH/kernel/obsx"
	"github.com/ZoneCNH/kernel/retryx"
	"github.com/ZoneCNH/kernel/syncx"
)

func TestRetryPolicyGoldenBehavior(t *testing.T) {
	policy := retryx.DefaultRetryPolicy()
	actual := struct {
		MaxAttempts int      `json:"max_attempts"`
		BaseDelay   string   `json:"base_delay"`
		MaxDelay    string   `json:"max_delay"`
		Delays      []string `json:"delays"`
	}{
		MaxAttempts: policy.MaxAttempts,
		BaseDelay:   policy.BaseDelay.String(),
		MaxDelay:    policy.MaxDelay.String(),
	}
	for attempt := 0; attempt <= 5; attempt++ {
		actual.Delays = append(actual.Delays, policy.Delay(attempt).String())
	}
	assertGoldenJSON(t, "examples/golden/retry-policy-default.json", actual)
}

func TestObsSecretRedactionGoldenBehavior(t *testing.T) {
	secret := obsx.NewSecretString("super-secret-token")
	actual := struct {
		String   string `json:"string"`
		JSON     string `json:"json"`
		Sanitize any    `json:"sanitize"`
		IsZero   bool   `json:"is_zero"`
	}{
		String:   secret.String(),
		Sanitize: secret.Sanitize(),
		IsZero:   secret.IsZero(),
	}
	encoded, err := json.Marshal(secret)
	if err != nil {
		t.Fatalf("marshal secret: %v", err)
	}
	if strings.Contains(string(encoded), secret.Reveal()) || strings.Contains(actual.String, secret.Reveal()) {
		t.Fatalf("secret redaction leaked raw value")
	}
	actual.JSON = string(encoded)
	assertGoldenJSON(t, "examples/golden/obs-secret-redaction.json", actual)
}

func TestLifecycleRollbackOrderGoldenBehavior(t *testing.T) {
	var order []string
	manager := lifecycx.NewManager(
		&goldenComponent{name: "alpha", order: &order},
		&goldenComponent{name: "beta", order: &order},
		&goldenComponent{name: "gamma", order: &order, startErr: errors.New("gamma start failed")},
	)
	err := manager.Start(context.Background())
	if err == nil || err.Error() != "gamma start failed" {
		t.Fatalf("Start() error = %v, want gamma start failed", err)
	}
	actual := struct {
		Error string   `json:"error"`
		Order []string `json:"order"`
	}{Error: err.Error(), Order: order}
	assertGoldenJSON(t, "examples/golden/lifecycle-rollback-order.json", actual)
}

func TestWorkerGroupErrorAggregationGoldenBehavior(t *testing.T) {
	group := syncx.NewWorkerGroup(context.Background())
	var observedCancellation atomic.Bool
	group.Go(func(context.Context) error { return errors.New("primary failure") })
	group.Go(func(ctx context.Context) error {
		<-ctx.Done()
		observedCancellation.Store(true)
		return nil
	})
	err := group.Wait()
	if err == nil || err.Error() != "primary failure" {
		t.Fatalf("Wait() error = %v, want primary failure", err)
	}
	actual := struct {
		Policy               string `json:"policy"`
		Error                string `json:"error"`
		ObservedCancellation bool   `json:"observed_cancellation"`
	}{Policy: "first-error", Error: err.Error(), ObservedCancellation: observedCancellation.Load()}
	assertGoldenJSON(t, "examples/golden/sync-workergroup-aggregation.json", actual)
}

type goldenComponent struct {
	name     string
	order    *[]string
	startErr error
}

func (c *goldenComponent) Name() string { return c.name }
func (c *goldenComponent) Start(context.Context) error {
	*c.order = append(*c.order, "start:"+c.name)
	return c.startErr
}
func (c *goldenComponent) Stop(context.Context) error {
	*c.order = append(*c.order, "stop:"+c.name)
	return nil
}

func assertGoldenJSON(t *testing.T, path string, value any) {
	t.Helper()
	data, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		t.Fatalf("marshal golden value: %v", err)
	}
	data = append(data, '\n')
	want, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read golden %s: %v", path, err)
	}
	if !reflect.DeepEqual(data, want) {
		t.Fatalf("golden mismatch for %s\ngot:\n%s\nwant:\n%s", path, data, want)
	}
}

var _ = time.Second
