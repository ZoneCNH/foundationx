package main

import (
	"context"
	"fmt"

	"github.com/ZoneCNH/kernel/contextx"
)

func run() (bool, string, bool) {
	key := contextx.NewKey[string]("trace-id")

	ctx := context.Background()
	ctx = contextx.WithValue(ctx, key, "abc-123")

	id, ok := contextx.Value(ctx, key)
	isDone := contextx.IsDone(ctx)
	return ok, id, isDone
}

func main() {
	ok, id, isDone := run()
	fmt.Println("ok:", ok)
	fmt.Println("id:", id)
	fmt.Println("done:", isDone)
}
