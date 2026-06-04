package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"

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

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	fmt.Println("application started (send SIGINT/SIGTERM to stop)")

	// Block until signal received.
	<-ctx.Done()
	fmt.Println("signal received, shutting down...")

	if err := mgr.Shutdown(context.Background()); err != nil {
		fmt.Fprintf(os.Stderr, "shutdown error: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("shutdown complete")
}
