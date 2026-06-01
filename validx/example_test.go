package validx_test

import "github.com/ZoneCNH/kernel/validx"

func ExampleRequireNonEmpty() {
	_ = validx.RequireNonEmpty("value", "name")
}
