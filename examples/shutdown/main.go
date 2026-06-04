package main

import (
	"context"
	"fmt"
	"os"
	"syscall"
	"time"

	"github.com/ZoneCNH/kernel/shutdownx"
)

func main() {
	mgr := shutdownx.NewManager()

	mgr.Register(shutdownx.HookFunc{
		NameValue: "database",
		Fn: func(ctx context.Context) error {
			fmt.Println("closing database connection")
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

	ctx, stop := shutdownx.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()
	done := time.AfterFunc(10*time.Millisecond, stop)
	defer done.Stop()

	fmt.Println("application started (send SIGINT/SIGTERM to stop)")

	<-ctx.Done()
	fmt.Println("shutdown requested, shutting down...")

	if err := mgr.Shutdown(context.Background()); err != nil {
		fmt.Fprintf(os.Stderr, "shutdown error: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("shutdown complete")
}
