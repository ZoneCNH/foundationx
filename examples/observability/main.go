package main

import (
	"context"
	"fmt"

	"github.com/ZoneCNH/kernel/obsx"
)

func run() string {
	logger := obsx.NoopLogger{}
	logger.Info(context.Background(), "startup", obsx.Field{Key: "scope", Value: "demo"})
	return fmt.Sprint(obsx.SecretString("hidden"))
}

func main() {
	fmt.Println(run())
}
