package main

import (
	"fmt"

	"github.com/ZoneCNH/kernel/errx"
)

func run() (string, bool, bool) {
	err := errx.NewError(errx.ErrorKindUnavailable, "example.Connect", "dependency unavailable").WithRetryable(true)

	isUnavailable := errx.IsKind(err, errx.ErrorKindUnavailable)
	retryable := err.Retryable
	return err.Error(), isUnavailable, retryable
}

func main() {
	msg, isUnavailable, retryable := run()
	fmt.Println(msg)
	fmt.Println("is_unavailable:", isUnavailable)
	fmt.Println("retryable:", retryable)
}
