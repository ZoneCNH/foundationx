package contextx_test

import (
	"context"
	"fmt"
	"time"

	"github.com/ZoneCNH/kernel/contextx"
	"github.com/ZoneCNH/kernel/timex"
)

func Example() {
	// Create typed keys
	requestID := contextx.NewKey[string]("request-id")
	userID := contextx.NewKey[int]("user-id")

	// Set values in context
	ctx := context.Background()
	ctx = contextx.WithValue(ctx, requestID, "abc-123")
	ctx = contextx.WithValue(ctx, userID, 42)

	// Get values
	if id, ok := contextx.Value(ctx, requestID); ok {
		fmt.Println("Request ID:", id)
	}
	if id, ok := contextx.Value(ctx, userID); ok {
		fmt.Println("User ID:", id)
	}

	// Check deadline
	fmt.Println("Has deadline:", contextx.HasDeadline(ctx))

	// Use with clock for testing
	clock := timex.NewFixedClock(time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC))
	_, hasDeadline := contextx.DeadlineRemaining(ctx, clock)
	fmt.Println("Deadline remaining:", hasDeadline)

	// Output:
	// Request ID: abc-123
	// User ID: 42
	// Has deadline: false
	// Deadline remaining: false
}
