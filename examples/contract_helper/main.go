package main

import (
	"fmt"
	"testing"

	"github.com/ZoneCNH/kernel/contracttest"
	"github.com/ZoneCNH/kernel/errx"
)

func main() {
	contracttest.AssertErrorKind(&testing.T{}, errx.NewError(errx.ErrorKindValidation, "example", "bad"), errx.ErrorKindValidation)
	fmt.Println("contract helper compiled")
}
