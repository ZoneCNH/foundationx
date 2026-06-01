package main

import (
	"fmt"

	"github.com/ZoneCNH/foundationx/pkg/foundationx"
)

func main() {
	err := foundationx.NewError(
		foundationx.ErrorKindUnavailable,
		"example.Connect",
		"dependency unavailable",
	).WithRetryable(true)

	fmt.Println(err)
	fmt.Println("is_unavailable:", foundationx.IsKind(err, foundationx.ErrorKindUnavailable))
	fmt.Println("retryable:", err.Retryable)
}
