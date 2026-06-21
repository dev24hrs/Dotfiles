# Go Development Standards

Help Claude write readable and maintainable Go code that conforms to Go community conventions. This skill integrates the core guidelines of [Effective Go](https://go.dev/doc/effective_go) & [Google Go Style Guide](https://google.github.io/styleguide/go/) & [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md).

Users provide Go code, a description of their requirements, or a problem, and you output code or suggestions that conform to the idiomatic Go style.

## 1.Tech Stack

- **Language**: Go 1.24+
- **Architecture**: Clean Architecture with Domain-Driven Design
- **API**: gRPC, REST (Chi/Gin/Echo), GraphQL (gqlgen)
- **Database**: PostgreSQL (pgx + sqlc), MongoDB, Redis (go-redis)
- **Message Queue**: Apache Kafka (franz-go), NATS, RabbitMQ
- **Observability**: OpenTelemetry, Jaeger, Prometheus, Grafana, slog
- **Testing**: Testify, mockery/GoMock, testcontainers-go
- **CLI**: Cobra, Viper, GoReleaser
- **Security**: JWT, OAuth2/OIDC, TLS
- **Deployment**: Docker (distroless), Kubernetes, Helm

## 2.Modularity & Simplicity

- **Single Responsibility:** Every file, type, and function should do one thing.
- **Short Functions:** Keep functions under 30 lines when possible.
- **Descriptive Names:** Use meaningful file, type, and function names (follow [Google Go standards](https://google.github.io/styleguide/go/decisions)).
- **No Printing/Direct Error Handling:** Never log or print errors except via centralized logging and error handling modules.

## 3.Concurrency

- Use goroutines and channels where suitable (for parallelism and asynchronous tasks).
- Avoid concurrency when it makes code less readable or more complex.
- Prefer standard library slice and range patterns over manual index loops for data processing; use `/pkg/vector` helpers where numeric batch operations are needed.
- Always document concurrent code with a comment explaining the synchronization strategy.

## 4.Error Management

- **Centralize Errors:** Define all error types and helpers in `/internal/errors/errors.go`.
- **Propagate Errors:** Always return errors to a single handling point, never handle or print errors directly in business logic.
- **Error Wrapping:** Use Go's error wrapping (`fmt.Errorf("context: %w", err)`) for error chain inspection; `%w` does not capture stack traces.
- **Return Style:** Return `(result, error)` instead of named returns unless named returns are necessary for documentation.
- **No Silent Failures:** Always check and return errors, never ignore them.

## 5.Logging

- **Centralized Logging:** Implement all logging in `/internal/logging/logger.go` using a standard Go logger or a third-party package.
- Never log directly in modules; always call the logging package.
- Keep log messages meaningful and context-rich.

## 6.Code Quality

- **DRY:** Avoid duplication; use helpers or utility packages for repeated logic.
- **Readability:** Prefer clarity over cleverness. Add comments for complex logic.
- **Scalability:** Organize code into modules and packages so new features can be added without major refactoring.

## 7.Performance

- Prefer `strings.Builder` for string concatenation over `+` or `fmt.Sprintf` in hot paths.
- Pre-allocate slices and maps when the size is known: `make([]T, 0, length)`.
- Avoid unnecessary allocations in loops; reuse buffers where possible.

## 8.Naming Conventions

- File, function, and variable names should be descriptive and follow Go's camelCase/PascalCase conventions (snake_case is not idiomatic Go).
- No abbreviations except common ones (ctx, err, req, resp, cfg, etc.).
- Use singular names for files and types unless a plural is more semantically correct.
- Keep method receivers short (1-3 letters), e.g., `func (r *Repository)`.
- Use `internal/` for packages that should not be exported outside the module.

## 9.Context Propagation

- Always accept `context.Context` as the first parameter in handlers, services, and repository methods.
- Never store a context in a struct field; pass it explicitly through the call chain.
- Respect context cancellation: check `ctx.Err()` in long-running loops or before expensive operations.

## 10.Interface Design

- Define interfaces in the package that **consumes** them, not the package that implements them (Go's consumer-side interface idiom).
- Keep interfaces small: prefer one or two methods over large interface types.
- Only introduce an interface when you have more than one implementation or need to decouple for testing.

## 11.Dependency Injection

- Wire dependencies through constructor functions (`NewService(repo Repository, log Logger) *Service`), not global variables or `init()`.
- Avoid using `init()` for side effects; prefer explicit initialization in `main.go`.
- Use `google/wire` for dependency wiring in all but the smallest projects.

## 12.Testing

- Write table-driven tests using `t.Run` for clear sub-test naming.
- Place unit tests in `_test.go` files alongside the code they test.
- Use interfaces and constructor injection to allow test doubles without patching globals.
- Integration tests go under `/test`; keep them behind a build tag (e.g., `//go:build integration`) so they do not run with `go test ./...` by default.
- Aim for tests that verify behavior, not implementation details.
