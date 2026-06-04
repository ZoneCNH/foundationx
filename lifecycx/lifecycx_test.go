package lifecycx

import (
	"context"
	"errors"
	"reflect"
	"testing"
)

type comp struct {
	name  string
	calls *[]string
	fail  bool
}

func (c comp) Name() string { return c.name }
func (c comp) Start(context.Context) error {
	*c.calls = append(*c.calls, "start:"+c.name)
	if c.fail {
		return errors.New("fail")
	}
	return nil
}
func (c comp) Stop(context.Context) error { *c.calls = append(*c.calls, "stop:"+c.name); return nil }
func TestInterfaces(t *testing.T) {
	var _ Starter = comp{}
	var _ Stopper = comp{}
	var _ Component = comp{}
}
func TestManagerStartStopOrder(t *testing.T) {
	calls := []string{}
	m := NewManager(comp{"a", &calls, false}, comp{"b", &calls, false})
	if err := m.Start(context.Background()); err != nil {
		t.Fatal(err)
	}
	if err := m.Stop(context.Background()); err != nil {
		t.Fatal(err)
	}
	want := []string{"start:a", "start:b", "stop:b", "stop:a"}
	if !reflect.DeepEqual(calls, want) {
		t.Fatalf("%v", calls)
	}
}
func TestManagerStopsStartedOnFailure(t *testing.T) {
	calls := []string{}
	m := NewManager(comp{"a", &calls, false}, comp{"b", &calls, true})
	if err := m.Start(context.Background()); err == nil {
		t.Fatal("want error")
	}
	want := []string{"start:a", "start:b", "stop:a"}
	if !reflect.DeepEqual(calls, want) {
		t.Fatalf("%v", calls)
	}
}

func TestManagerComponentsReturnsCopy(t *testing.T) {
	calls := []string{}
	a := comp{"a", &calls, false}
	b := comp{"b", &calls, false}
	m := NewManager(a, b)
	components := m.Components()
	if len(components) != 2 || components[0].Name() != "a" || components[1].Name() != "b" {
		t.Fatalf("unexpected components: %v", components)
	}
	components[0] = b
	if got := m.Components()[0].Name(); got != "a" {
		t.Fatalf("components slice aliases manager state: %s", got)
	}
}

type stopFailComp struct {
	name    string
	calls   *[]string
	stopErr error
}

func (c stopFailComp) Name() string { return c.name }
func (c stopFailComp) Start(context.Context) error {
	*c.calls = append(*c.calls, "start:"+c.name)
	return nil
}
func (c stopFailComp) Stop(context.Context) error {
	*c.calls = append(*c.calls, "stop:"+c.name)
	return c.stopErr
}

func TestManagerStopContinuesAndJoinsErrors(t *testing.T) {
	calls := []string{}
	errA := errors.New("stop a")
	errB := errors.New("stop b")
	m := NewManager(
		stopFailComp{name: "a", calls: &calls, stopErr: errA},
		stopFailComp{name: "b", calls: &calls, stopErr: errB},
	)
	if err := m.Start(context.Background()); err != nil {
		t.Fatal(err)
	}
	err := m.Stop(context.Background())
	if !errors.Is(err, errA) || !errors.Is(err, errB) {
		t.Fatalf("joined error = %v", err)
	}
	want := []string{"start:a", "start:b", "stop:b", "stop:a"}
	if !reflect.DeepEqual(calls, want) {
		t.Fatalf("%v", calls)
	}
}

func TestManagerStartRollbackJoinsStopErrors(t *testing.T) {
	calls := []string{}
	stopErr := errors.New("stop a")
	m := NewManager(
		stopFailComp{name: "a", calls: &calls, stopErr: stopErr},
		comp{name: "b", calls: &calls, fail: true},
	)
	err := m.Start(context.Background())
	if err == nil {
		t.Fatal("want start error")
	}
	if !errors.Is(err, stopErr) {
		t.Fatalf("rollback stop error not joined: %v", err)
	}
	want := []string{"start:a", "start:b", "stop:a"}
	if !reflect.DeepEqual(calls, want) {
		t.Fatalf("%v", calls)
	}
}

func TestManagerStopWithoutStartIsNoop(t *testing.T) {
	calls := []string{}
	m := NewManager(comp{"a", &calls, false}, comp{"b", &calls, false})
	if err := m.Stop(context.Background()); err != nil {
		t.Fatal(err)
	}
	if len(calls) != 0 {
		t.Fatalf("expected no calls, got %v", calls)
	}
}

func TestManagerStopIdempotent(t *testing.T) {
	calls := []string{}
	m := NewManager(comp{"a", &calls, false}, comp{"b", &calls, false})
	if err := m.Start(context.Background()); err != nil {
		t.Fatal(err)
	}
	if err := m.Stop(context.Background()); err != nil {
		t.Fatal(err)
	}
	if err := m.Stop(context.Background()); err != nil {
		t.Fatal(err)
	}
	want := []string{"start:a", "start:b", "stop:b", "stop:a"}
	if !reflect.DeepEqual(calls, want) {
		t.Fatalf("expected single stop sequence, got %v", calls)
	}
}
