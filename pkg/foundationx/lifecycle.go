package foundationx

import "context"

// Starter is implemented by resources that can start with context control.
type Starter interface {
	Start(ctx context.Context) error
}

// Closer is implemented by resources that can close with context control.
type Closer interface {
	Close(ctx context.Context) error
}

// Lifecycle combines start and close contracts.
type Lifecycle interface {
	Starter
	Closer
}
