package contracts

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"reflect"
	"testing"

	"github.com/ZoneCNH/kernel/lifecycx"
	"github.com/ZoneCNH/kernel/obsx"
	"github.com/ZoneCNH/kernel/retryx"
	"github.com/ZoneCNH/kernel/syncx"
)

func TestGoldenRetryPolicyDefault(t *testing.T) {
	var want struct {
		MaxAttempts int      `json:"max_attempts"`
		BaseDelay   string   `json:"base_delay"`
		MaxDelay    string   `json:"max_delay"`
		Delays      []string `json:"delays"`
	}
	readGolden(t, "retry-policy-default.json", &want)

	policy := retryx.DefaultRetryPolicy()
	got := struct {
		MaxAttempts int      `json:"max_attempts"`
		BaseDelay   string   `json:"base_delay"`
		MaxDelay    string   `json:"max_delay"`
		Delays      []string `json:"delays"`
	}{
		MaxAttempts: policy.MaxAttempts,
		BaseDelay:   policy.BaseDelay.String(),
		MaxDelay:    policy.MaxDelay.String(),
	}
	for attempt := 0; attempt <= 4; attempt++ {
		got.Delays = append(got.Delays, policy.Delay(attempt).String())
	}
	assertDeepEqual(t, got, want)
}

func TestGoldenSecretRedaction(t *testing.T) {
	var want struct {
		Empty        string `json:"empty"`
		Redacted     string `json:"redacted"`
		JSON         string `json:"json"`
		IsZeroEmpty  bool   `json:"is_zero_empty"`
		IsZeroSecret bool   `json:"is_zero_secret"`
	}
	readGolden(t, "obsx-secret-redaction.json", &want)

	encoded, err := obsx.NewSecretString("secret").MarshalJSON()
	if err != nil {
		t.Fatalf("marshal secret string: %v", err)
	}
	got := struct {
		Empty        string `json:"empty"`
		Redacted     string `json:"redacted"`
		JSON         string `json:"json"`
		IsZeroEmpty  bool   `json:"is_zero_empty"`
		IsZeroSecret bool   `json:"is_zero_secret"`
	}{
		Empty:        obsx.NewSecretString("").String(),
		Redacted:     obsx.NewSecretString("secret").String(),
		JSON:         string(encoded),
		IsZeroEmpty:  obsx.NewSecretString("").IsZero(),
		IsZeroSecret: obsx.NewSecretString("secret").IsZero(),
	}
	assertDeepEqual(t, got, want)
}

func TestGoldenLifecycleRollbackOrder(t *testing.T) {
	var want struct {
		Error  string   `json:"error"`
		Events []string `json:"events"`
	}
	readGolden(t, "lifecycx-rollback-order.json", &want)

	events := []string{}
	manager := lifecycx.NewManager(
		goldenComponent{name: "a", events: &events},
		goldenComponent{name: "b", events: &events},
		goldenComponent{name: "c", events: &events, startErr: errors.New("start c")},
	)
	err := manager.Start(context.Background())
	if err == nil {
		t.Fatal("expected start error")
	}
	got := struct {
		Error  string   `json:"error"`
		Events []string `json:"events"`
	}{Error: err.Error(), Events: events}
	assertDeepEqual(t, got, want)
}

func TestGoldenWorkerGroupFirstError(t *testing.T) {
	var want struct {
		Error string `json:"error"`
	}
	readGolden(t, "syncx-first-error.json", &want)

	group := syncx.NewWorkerGroup(context.Background())
	group.Go(func(context.Context) error { return errors.New("worker failed") })
	err := group.Wait()
	if err == nil {
		t.Fatal("expected worker error")
	}
	got := struct {
		Error string `json:"error"`
	}{Error: err.Error()}
	assertDeepEqual(t, got, want)
}

type goldenComponent struct {
	name     string
	events   *[]string
	startErr error
}

func (c goldenComponent) Name() string { return c.name }
func (c goldenComponent) Start(context.Context) error {
	*c.events = append(*c.events, "start "+c.name)
	return c.startErr
}
func (c goldenComponent) Stop(context.Context) error {
	*c.events = append(*c.events, "stop "+c.name)
	return nil
}

func readGolden(t *testing.T, name string, out any) {
	t.Helper()
	data, err := os.ReadFile("examples/golden/" + name)
	if err != nil {
		t.Fatalf("read golden %s: %v", name, err)
	}
	if err := json.Unmarshal(data, out); err != nil {
		t.Fatalf("parse golden %s: %v", name, err)
	}
}

func assertDeepEqual(t *testing.T, got any, want any) {
	t.Helper()
	if !reflect.DeepEqual(got, want) {
		gotJSON, _ := json.MarshalIndent(got, "", "  ")
		wantJSON, _ := json.MarshalIndent(want, "", "  ")
		t.Fatalf("golden mismatch\ngot:  %s\nwant: %s", gotJSON, wantJSON)
	}
}
