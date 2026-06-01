package main

import (
	"context"
	"fmt"

	"github.com/ZoneCNH/kernel/obsx"
)

func main() {
	logger := obsx.NoopLogger{}
	logger.Info(context.Background(), "startup", obsx.Field{Key: "scope", Value: "demo"})
	fmt.Println(obsx.SecretString("hidden"))
}
