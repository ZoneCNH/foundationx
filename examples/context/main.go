package main

import (
	"context"
	"fmt"

	"github.com/ZoneCNH/kernel/contextx"
)

func main() {
	key := contextx.NewKey[string]("trace-id")

	ctx := context.Background()
	ctx = contextx.WithValue(ctx, key, "abc-123")

	id, ok := contextx.Value(ctx, key)
	fmt.Println("ok:", ok)
	fmt.Println("id:", id)
	fmt.Println("done:", contextx.IsDone(ctx))
}
