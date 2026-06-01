package contracts

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"reflect"
	"testing"
	"time"

	"github.com/ZoneCNH/kernel/lifecycx"
	"github.com/ZoneCNH/kernel/obsx"
	"github.com/ZoneCNH/kernel/retryx"
	"github.com/ZoneCNH/kernel/syncx"
)

type retryDelayGolden struct {
	BaseDelay string `json:"base_delay"`
	MaxDelay  string `json:"max_delay"`
	Attempts  []struct {
		Attempt int    `json:"attempt"`
		Delay   string `json:"delay"`
	} `json:"attempts"`
	Jitter []struct {
		Attempt  int     `json:"attempt"`
		Ratio    float64 `json:"ratio"`
		Fraction float64 `json:"fraction"`
		Delay    string  `json:"delay"`
	} `json:"jitter"`
}

func TestRetryDelayGoldenContract(t *testing.T) {
	golden := readJSONGolden[retryDelayGolden](t, "retry-delays.json")
	baseDelay := mustParseDuration(t, golden.BaseDelay)
	maxDelay := mustParseDuration(t, golden.MaxDelay)
	policy := retryx.RetryPolicy{MaxAttempts: 4, BaseDelay: baseDelay, MaxDelay: maxDelay}

	for _, tc := range golden.Attempts {
		want := mustParseDuration(t, tc.Delay)
		if got := policy.Delay(tc.Attempt); got != want {
			t.Fatalf("Delay(%d) = %s, want %s", tc.Attempt, got, want)
		}
	}
	for _, tc := range golden.Jitter {
		want := mustParseDuration(t, tc.Delay)
		if got := policy.DelayWithJitter(tc.Attempt, tc.Ratio, tc.Fraction); got != want {
			t.Fatalf("DelayWithJitter(%d, %v, %v) = %s, want %s", tc.Attempt, tc.Ratio, tc.Fraction, got, want)
		}
	}
}

type obsxRedactionGolden struct {
	EmptyString      string `json:"empty_string"`
	NonEmptyString   string `json:"non_empty_string"`
	NonEmptySanitize string `json:"non_empty_sanitize"`
	NonEmptyJSON     string `json:"non_empty_json"`
	Reveal           string `json:"reveal"`
	EmptyIsZero      bool   `json:"empty_is_zero"`
	NonEmptyIsZero   bool   `json:"non_empty_is_zero"`
}

func TestObsxRedactionGoldenContract(t *testing.T) {
	golden := readJSONGolden[obsxRedactionGolden](t, "obsx-redaction.json")
	empty := obsx.NewSecretString("")
	secret := obsx.NewSecretString("secret-token")
	payload, err := secret.MarshalJSON()
	if err != nil {
		t.Fatalf("MarshalJSON: %v", err)
	}
	var jsonValue string
	if err := json.Unmarshal(payload, &jsonValue); err != nil {
		t.Fatalf("unmarshal secret JSON: %v", err)
	}

	got := obsxRedactionGolden{
		EmptyString:      empty.String(),
		NonEmptyString:   secret.String(),
		NonEmptySanitize: secret.Sanitize().(string),
		NonEmptyJSON:     jsonValue,
		Reveal:           secret.Reveal(),
		EmptyIsZero:      empty.IsZero(),
		NonEmptyIsZero:   secret.IsZero(),
	}
	if got != golden {
		t.Fatalf("obsx redaction = %+v, want %+v", got, golden)
	}
}

type lifecycleGolden struct {
	StartError string   `json:"start_error"`
	Events     []string `json:"events"`
}

func TestLifecycleRollbackGoldenContract(t *testing.T) {
	golden := readJSONGolden[lifecycleGolden](t, "lifecycx-rollback-order.json")
	events := []string{}
	manager := lifecycx.NewManager(
		goldenComponent{name: "a", events: &events},
		goldenComponent{name: "b", events: &events},
		goldenComponent{name: "c", events: &events, startErr: errors.New(golden.StartError)},
	)
	err := manager.Start(context.Background())
	if err == nil || err.Error() != golden.StartError {
		t.Fatalf("Start error = %v, want %q", err, golden.StartError)
	}
	if !reflect.DeepEqual(events, golden.Events) {
		t.Fatalf("events = %#v, want %#v", events, golden.Events)
	}
}

type goldenComponent struct {
	name     string
	events   *[]string
	startErr error
}

func (c goldenComponent) Name() string { return c.name }
func (c goldenComponent) Start(context.Context) error {
	*c.events = append(*c.events, "start:"+c.name)
	return c.startErr
}
func (c goldenComponent) Stop(context.Context) error {
	*c.events = append(*c.events, "stop:"+c.name)
	return nil
}

type syncxGolden struct {
	ReturnedError         string `json:"returned_error"`
	SecondWorkerCancelled bool   `json:"second_worker_cancelled"`
}

func TestSyncxWorkerGroupGoldenContract(t *testing.T) {
	golden := readJSONGolden[syncxGolden](t, "syncx-workergroup-first-error.json")
	group := syncx.NewWorkerGroup(context.Background())
	started := make(chan struct{})
	cancelled := make(chan bool, 1)

	group.Go(func(context.Context) error {
		<-started
		return errors.New(golden.ReturnedError)
	})
	group.Go(func(ctx context.Context) error {
		close(started)
		<-ctx.Done()
		cancelled <- true
		return nil
	})

	err := group.Wait()
	if err == nil || err.Error() != golden.ReturnedError {
		t.Fatalf("Wait error = %v, want %q", err, golden.ReturnedError)
	}
	if got := <-cancelled; got != golden.SecondWorkerCancelled {
		t.Fatalf("second worker cancelled = %v, want %v", got, golden.SecondWorkerCancelled)
	}
}

func readJSONGolden[T any](t *testing.T, name string) T {
	t.Helper()
	var out T
	data, err := os.ReadFile(filepath.Join("golden", name))
	if err != nil {
		t.Fatalf("read golden %s: %v", name, err)
	}
	if err := json.Unmarshal(data, &out); err != nil {
		t.Fatalf("parse golden %s: %v", name, err)
	}
	return out
}

func mustParseDuration(t *testing.T, value string) time.Duration {
	t.Helper()
	d, err := time.ParseDuration(value)
	if err != nil {
		t.Fatalf("parse duration %q: %v", value, err)
	}
	return d
}
