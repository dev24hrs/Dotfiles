# Go Development Standards & Skills

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

### Modern Go: Stdlib-First Idioms

Prefer modern standard-library APIs over legacy patterns. Below is a concrete before/after reference.

#### Slices & Maps

| Legacy (avoid)                                   | Modern (prefer)                                                | Since   |
| ------------------------------------------------ | -------------------------------------------------------------- | ------- |
| `for i := range s { if s[i] == v { ... } }`      | `slices.Contains(s, v)`                                        | Go 1.21 |
| `for _, v := range s { if v == target { ... } }` | `slices.Index(s, target)`                                      | Go 1.21 |
| manual loop to clone a slice                     | `slices.Clone(s)`                                              | Go 1.21 |
| manual loop to copy a map                        | `maps.Clone(m)`                                                | Go 1.21 |
| `m[k] = v; m[k] = v2; delete(m, old)` in batch   | `maps.Copy(dst, src)`                                          | Go 1.21 |
| `for k := range m { delete(m, k) }`              | `clear(m)`                                                     | Go 1.21 |
| `s = s[:0]` to reset a slice                     | `clear(s)`                                                     | Go 1.21 |
| `for i, v := range s { s[i] = f(v) }`            | `slices.Replace(s, 0, len(s), f(v))` or collect into new slice | Go 1.22 |

#### Sort

| Legacy (avoid)                                                    | Modern (prefer)                                                       | Since   |
| ----------------------------------------------------------------- | --------------------------------------------------------------------- | ------- |
| `sort.Ints(x)`                                                    | `slices.Sort(x)`                                                      | Go 1.22 |
| `sort.Strings(x)`                                                 | `slices.Sort(x)`                                                      | Go 1.22 |
| `sort.Float64s(x)`                                                | `slices.Sort(x)`                                                      | Go 1.22 |
| `sort.Sort(sort.IntSlice(x))`                                     | `slices.Sort(x)`                                                      | Go 1.22 |
| `sort.Sort(sort.StringSlice(x))`                                  | `slices.Sort(x)`                                                      | Go 1.22 |
| `sort.Slice(x, func(i, j int) bool { return x[i] < x[j] })`       | `slices.Sort(x)`                                                      | Go 1.22 |
| `sort.Slice(x, func(i, j int) bool { return less(x[i], x[j]) })`  | `slices.SortFunc(x, less)`                                            | Go 1.22 |
| `sort.SliceStable(x, func(i, j int) bool { return ... })`         | `slices.SortStableFunc(x, cmp)`                                       | Go 1.22 |
| `sort.Reverse(sort.IntSlice(x))` + `sort.Sort(...)`               | `slices.SortFunc(x, func(a, b int) int { return cmp.Compare(b, a) })` | Go 1.22 |
| `sort.IntsAreSorted(x)`                                           | `slices.IsSorted(x)`                                                  | Go 1.22 |
| `sort.StringsAreSorted(x)`                                        | `slices.IsSorted(x)`                                                  | Go 1.22 |
| `sort.Float64sAreSorted(x)`                                       | `slices.IsSorted(x)`                                                  | Go 1.22 |
| `sort.IsSorted(sort.StringSlice(x))`                              | `slices.IsSorted(x)`                                                  | Go 1.22 |
| `sort.Search(n, func(i int) bool { return x[i] >= target })`      | `slices.BinarySearch(x, target)`                                      | Go 1.22 |
| `sort.Search(n, func(i int) bool { return cond(x[i]) })` (custom) | `slices.BinarySearchFunc(x, target, cmp)`                             | Go 1.22 |

#### Builtins & Language

| Legacy (avoid)                            | Modern (prefer)                    | Since   |
| ----------------------------------------- | ---------------------------------- | ------- |
| `interface{}`                             | `any`                              | Go 1.18 |
| `if x > y { max = x } else { max = y }`   | `max(x, y)`                        | Go 1.21 |
| `if x < y { min = x } else { min = y }`   | `min(x, y)`                        | Go 1.21 |
| `fmt.Sprintf("%s/%s", a, b)` in hot paths | `strings.Builder` or `fmt.Appendf` | Go 1.19 |

#### Strings

| Legacy (avoid)                                      | Modern (prefer)                           | Since   |
| --------------------------------------------------- | ----------------------------------------- | ------- |
| `strings.SplitN(s, sep, 2)` to get two parts        | `strings.Cut(s, sep)`                     | Go 1.18 |
| `strings.TrimPrefix` + `strings.TrimSuffix` chained | `strings.CutPrefix` / `strings.CutSuffix` | Go 1.20 |

#### Errors

| Legacy (avoid)                                       | Modern (prefer)                  | Since   |
| ---------------------------------------------------- | -------------------------------- | ------- |
| `err1.Error() + ": " + err2.Error()`                 | `errors.Join(err1, err2)`        | Go 1.20 |
| manual loop to collect multiple errors               | `errors.Join(errs...)`           | Go 1.20 |
| hand-rolled context cancellation cause               | `context.WithCancelCause(ctx)`   | Go 1.20 |
| `fmt.Errorf("context: %s", err)` (loses error chain) | `fmt.Errorf("context: %w", err)` | Go 1.13 |

#### HTTP

| Legacy (avoid)                           | Modern (prefer)                                      | Since   |
| ---------------------------------------- | ---------------------------------------------------- | ------- |
| `http.NewRequest(method, url, body)`     | `http.NewRequestWithContext(ctx, method, url, body)` | Go 1.13 |
| `http.Get(url)` (no context propagation) | `http.NewRequestWithContext` + `client.Do`           | Go 1.13 |

#### Concurrency

| Legacy (avoid)                                            | Modern (prefer)                                              | Since   |
| --------------------------------------------------------- | ------------------------------------------------------------ | ------- |
| `var once sync.Once; once.Do(func() { ... })` for a value | `sync.OnceValue(f)` / `sync.OnceValues(f)`                   | Go 1.21 |
| `var mu sync.Mutex` + manual Lock/Unlock around a map     | `sync.RWMutex` or consider `sync.Map` for specific use-cases | —       |

#### Guideline

- When both old and new forms exist, **always prefer the newer form** unless the project's `go.mod` version doesn't support it.
- Check the project's `go.mod` `go` directive before using any feature marked above — never use a feature from a version higher than the module declares.
- The Go compatibility promise means stdlib additions are safe: code that compiles with Go 1.N will compile with Go 1.N+1. Prefer stdlib over a third-party dependency that wraps the same functionality.

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
