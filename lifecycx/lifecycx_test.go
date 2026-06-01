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
