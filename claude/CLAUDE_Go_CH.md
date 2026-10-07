# Go 开发标准

帮助 Claude 编写符合 Go 社区规范、可读性强且易于维护的 Go 代码。本文档整合了 [Effective Go](https://go.dev/doc/effective_go)、[Google Go Style Guide](https://google.github.io/styleguide/go/) 和 [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md) 的核心指南。

用户提供 Go 代码、需求描述或问题，你输出符合 Go 惯用风格的代码或建议。

## 1. 技术栈

- **语言**：Go 1.24+
- **架构**：Clean Architecture 结合领域驱动设计（DDD）
- **API**：gRPC、REST（Chi/Gin/Echo）、GraphQL（gqlgen）
- **数据库**：PostgreSQL（pgx + sqlc）、MongoDB、Redis（go-redis）
- **消息队列**：Apache Kafka（franz-go）、NATS、RabbitMQ
- **可观测性**：OpenTelemetry、Jaeger、Prometheus、Grafana、slog
- **测试**：Testify、mockery/GoMock、testcontainers-go
- **CLI**：Cobra、Viper、GoReleaser
- **安全**：JWT、OAuth2/OIDC、TLS
- **部署**：Docker（distroless）、Kubernetes、Helm

## 2. 模块化与简洁性

- **单一职责**：每个文件、类型和函数只做一件事。
- **短函数**：函数尽量控制在 30 行以内。
- **命名清晰**：使用有意义且符合 [Google Go 命名标准](https://google.github.io/styleguide/go/decisions) 的文件名、类型名和函数名。
- **禁止裸打印/直接错误处理**：除通过集中式日志和错误处理模块外,不得在业务代码中直接打印或处理错误。

## 3. 并发

- 在合适的场景使用 goroutine 和 channel（用于并行和异步任务）。
- 当并发使代码可读性降低或逻辑更复杂时,避免使用并发。
- 数据处理优先使用标准库的切片和 range 模式,而非手动索引循环；数值批量操作可使用 `/pkg/vector` 辅助函数。
- 并发代码必须添加注释说明同步策略。

## 4. 错误管理

- **集中定义错误**：所有错误类型和辅助函数统一定义在 `/internal/errors/errors.go` 中。
- **向上传播错误**：错误始终返回到单一处理点,不得在业务逻辑中直接处理或打印。
- **错误包装**：使用 Go 的错误包装机制（`fmt.Errorf("context: %w", err)`）保留错误链以便排查；`%w` 不会捕获堆栈信息。
- **返回值风格**：使用 `(result, error)` 而非命名返回值,除非命名返回值是文档所必需。
- **不容忍静默失败**：始终检查并返回错误,绝不忽略。

## 5. 日志

- **集中管理日志**：所有日志实现在 `/internal/logging/logger.go` 中,使用标准 Go logger 或第三方库。
- 禁止在模块中直接打日志；始终调用日志包。
- 日志信息要富有意义且上下文丰富。

## 6. 代码质量

- **DRY（不重复）**：避免重复代码；使用辅助函数或工具包封装复用逻辑。
- **可读性优先**：清晰优于取巧。复杂逻辑必须加注释。
- **可扩展性**：代码按模块和包组织,确保新增功能无需大规模重构。

### 6.1 现代化 Go：标准库优先惯用法

优先使用现代标准库 API,而非旧式写法,在生成代码时,遵循以下优先级：

1. **标准库优先**：当标准库能提供足够解决方案时,优先使用标准库而非第三方依赖。引入新依赖需要说明理由（标准库方案缺失、存在缺陷、或过于冗长）。
2. **现代惯用法优于旧式写法**：使用语言现代/推荐的惯用法,而非早期版本的旧式模式。包括但不限于：
   - 函数声明（箭头函数、简洁方法语法等）
   - 集合操作（当可读性足够时，优先使用声明式/函数式 API 而非手动循环）
   - HTTP / I/O 操作（优先使用现代客户端 API 而非已废弃的旧 API）
   - 错误处理（优先使用语言原生模式而非手动拼凑的变通方案）
   - 类型系统（优先使用新式类型构造，而非 `any`/`Object`/`void*` 等逃逸手段）
3. **版本感知**：以项目工具链/配置文件（如 `go.mod`、`pyproject.toml`、`.nvmrc`）中声明的语言版本为准。不使用高于项目目标版本的新特性,也不使用项目目标版本中已废弃的写法。

## 7. 性能

- 在热路径中,优先使用 `strings.Builder` 拼接字符串，而非 `+` 或 `fmt.Sprintf`。
- 已知容量时预分配切片和 Map：`make([]T, 0, length)`。
- 避免在循环中进行不必要的内存分配；尽可能复用缓冲区。

## 8. 命名规范

- 文件名、函数名和变量名应具描述性,遵循 Go 的 camelCase/PascalCase 规范（snake_case 非 Go 惯用风格）。
- 除通用缩写外不缩写（如 ctx、err、req、resp、cfg 等）。
- 文件和类型使用单数命名,除非复数语义更准确。
- 方法接收器保持简短（1-3 个字符）,如 `func (r *Repository)`。
- 使用 `internal/` 路径保护不应被模块外导入的包。

## 9. Context 传播

- Handler、Service 和 Repository 方法的第一个参数始终接受 `context.Context`。
- 禁止将 context 存储在结构体字段中；应沿调用链显式传递。
- 尊重 context 取消信号：在长时间运行的循环或开销较大的操作之前检查 `ctx.Err()`。

## 10. 接口设计

- 在**消费**接口的包中定义接口,而非在实现接口的包中（Go 的消费侧接口惯用法）。
- 保持接口小巧：优先采用一两个方法的接口，而非大而全的接口类型。
- 只有在存在多个实现或需要解耦以便测试时才引入接口。

## 11. 依赖注入

- 通过构造函数注入依赖（`NewService(repo Repository, log Logger) *Service`）,而非全局变量或 `init()`。
- 避免使用 `init()` 产生副作用；优先在 `main.go` 中显式初始化。
- 除最小型项目外,均推荐使用 `google/wire` 进行依赖注入。

## 12. 测试

- 编写表格驱动测试,使用 `t.Run` 提供清晰的子测试名称。
- 单元测试放在被测代码同目录的 `_test.go` 文件中。
- 使用接口和构造函数注入来支持测试替身（test double）,避免 patch 全局变量。
- 集成测试放在 `/test` 目录下,并加上构建标签（如 `//go:build integration`）,确保 `go test ./...` 默认不执行集成测试。
- 目标：测试应验证行为,而非实现细节。
