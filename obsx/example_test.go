package obsx_test

import "github.com/ZoneCNH/kernel/obsx"

func ExampleNewSecretString() {
	secret := obsx.NewSecretString("token")
	_ = secret.Sanitize()
}
