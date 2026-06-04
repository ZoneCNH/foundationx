package shutdownx_test

import (
	"context"
	"fmt"

	"github.com/ZoneCNH/kernel/shutdownx"
)

func Example() {
	mgr := shutdownx.NewManager()

	mgr.Register(shutdownx.HookFunc{
		NameValue: "database",
		Fn: func(ctx context.Context) error {
			fmt.Println("closing database")
			return nil
		},
	})
	mgr.Register(shutdownx.HookFunc{
		NameValue: "http-server",
		Fn: func(ctx context.Context) error {
			fmt.Println("stopping http server")
			return nil
		},
	})

	err := mgr.Shutdown(context.Background())
	fmt.Println("error:", err)

	// Output:
	// stopping http server
	// closing database
	// error: <nil>
}
