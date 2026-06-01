package main

import (
	"fmt"

	"github.com/ZoneCNH/kernel/errx"
)

func main() {
	err := errx.NewError(errx.ErrorKindUnavailable, "example.Connect", "dependency unavailable").WithRetryable(true)

	fmt.Println(err)
	fmt.Println("is_unavailable:", errx.IsKind(err, errx.ErrorKindUnavailable))
	fmt.Println("retryable:", err.Retryable)
}
