package main

import (
	"fmt"
	"testing"

	"github.com/ZoneCNH/kernel/contracttest"
	"github.com/ZoneCNH/kernel/errx"
)

func run() bool {
	contracttest.AssertErrorKind(&testing.T{}, errx.NewError(errx.ErrorKindValidation, "example", "bad"), errx.ErrorKindValidation)
	return true
}

func main() {
	run()
	fmt.Println("contract helper compiled")
}
