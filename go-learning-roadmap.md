# Go 学习路线图：从 Java 到 Go 的系统进阶

> **目标读者**：有 Java 工程经验的开发者
> **学习周期**：12 周（每周 10-15 小时）
> **最终产出**：能独立设计并交付生产级 Go 服务

---

## 前言：Java → Go 思维转换

在开始学习之前，先明确两门语言在**设计哲学**上的根本差异。这比你记住语法细节更重要。

| 维度         | Java                              | Go                                              |
| ------------ | --------------------------------- | ----------------------------------------------- |
| **核心理念** | 面向对象，继承多态                | 组合优于继承，简单胜于聪明                      |
| **类型系统** | Nominal typing（名字决定类型）    | Structural typing（行为决定类型，接口自动满足） |
| **错误处理** | try-catch-finally 异常栈          | 显式返回 `error`，调用方必须处理                |
| **并发模型** | 线程池 + Future/CompletableFuture | goroutine + channel（CSP 模型）                 |
| **依赖管理** | Maven/Gradle + 中心仓库           | go.mod + 最小版本选择（MVS）                    |
| **框架文化** | Spring Boot 全家桶                | 标准库优先，按需引入轻量库                      |
| **泛型**     | 2004 年引入，功能完备             | 1.18 引入，刻意克制                             |
| **GC**       | 分代收集，调优参数多              | 低延迟优先，可调参数极少                        |
| **访问控制** | public/protected/private          | 首字母大小写决定导出/非导出                     |
| **运行时**   | JVM 启动慢，预热后快              | 编译为静态二进制，启动毫秒级                    |

**最重要的心态转变**：

1. **不要找 Spring Boot 的 Go 等价物** — Go 不是没有 Spring，而是不需要 Spring
2. **拥抱显式** — 隐式转换、注解魔法、AOP 在 Go 里被视为反模式
3. **把错误当作值** — 不是"抛出异常"，而是"返回一个可能出错的结果"
4. **接口是用来被"发现"的** — 你先实现，后抽象，不需要提前声明 `implements`

---

## 阶段一：基础语感（Week 1-3）

> **核心命题**：丢掉 Java 的书写习惯，建立 Go 的肌肉记忆

### 阶段目标

- 用 Go 标准库写出结构清晰的小程序
- 理解 Go 的类型系统、零值设计、包管理机制
- 能独立配置 Go 开发环境并管理依赖

### 核心主题

1. **环境与工具链**
   - Go 安装、GOPATH vs GOROOT、Go Modules（go.mod / go.sum）
   - 关键命令：`go build`、`go run`、`go fmt`、`go vet`、`go mod tidy`
   - `gofmt` 强格式化 — **没有代码风格争论，格式化是编译器级别的共识**

2. **基础语法**
   - 变量声明（`var` vs `:=`）、基本类型、零值语义
   - 控制流：`if`（支持前置语句）、`for`（唯一的循环关键字）、`switch`（默认不穿透）
   - 函数：多返回值、命名返回值、`defer`（后进先出）
   - **没有 `while`，没有 `do-while`，没有三元运算符** — 故意的

3. **复合类型**
   - Array（定长，值类型）vs Slice（动态，引用底层数组）
   - Map 的零值是 `nil`，写入会 panic
   - Struct：无继承，用嵌入（embedding）实现组合
   - `make()` vs `new()` 的区别

4. **方法与接口**
   - 方法接收者：值接收者 vs 指针接收者 — **这是最易错的点之一**
   - 接口：**隐式实现** — 结构体不需要声明它实现了哪个接口
   - 空接口 `interface{}` → 1.18 后用 `any`

5. **包与模块**
   - 包名与目录名的约定
   - 导出规则：首字母大写 = public，小写 = package-private
   - `internal/` 目录的特殊语义

### 推荐资源

| 资源                                            | 用法                                               |
| ----------------------------------------------- | -------------------------------------------------- |
| [A Tour of Go](https://go.dev/tour/)            | 交互式走一遍，2-3 小时完成                         |
| [Go by Example](https://gobyexample.com/)       | 随查随用，每个主题一页可运行代码                   |
| [_The Go Programming Language_](https://www.gopl.io/) 第 1-8 章 | 精读，重点理解第 4 章（复合类型）和第 6 章（方法） |
| [Effective Go](https://go.dev/doc/effective_go) | 通读一遍，标记不理解的部分                         |
| [How to Write Go Code](https://go.dev/doc/code) | 官方的项目组织指南                                 |

### 阶段项目：Godo — CLI 待办工具

**目标**：用纯标准库实现一个命令行待办事项管理工具。

```
$ godo add "读完 The Go Programming Language 第4章"
  ✓ 已添加任务 #1: 读完 The Go Programming Language 第4章

$ godo list
  #1 [ ] 读完 The Go Programming Language 第4章
  #2 [✓] 完成 A Tour of Go
  #3 [ ] 配置 Neovim LSP

$ godo done 1
  ✓ 完成任务 #1

$ godo remove 2
  ✓ 已删除任务 #2
```

**技术要求**：

- 使用 `flag` 包解析子命令（或 `os.Args` 手动解析）
- 用 JSON 文件持久化任务列表（`encoding/json` + `os.ReadFile`/`os.WriteFile`）
- 合理组织包结构：`cmd/godo/main.go` + 内部逻辑包
- 使用 `defer` 确保文件句柄关闭
- 错误要显式处理，不使用 `panic`

**自检清单**：

- [ ] 理解为什么 slice 作为函数参数时，修改元素会影响外部，但 `append` 不一定？
- [ ] `nil` slice 和 empty slice 的区别是什么？什么时候用哪个？
- [ ] 值接收者和指针接收者各在什么场景下使用？
- [ ] `defer` 的参数在什么时候求值？

### Java ↔ Go 对比速查

```go
// Java: List<String> items = new ArrayList<>();
items := []string{}           // 空 slice 字面量
items := make([]string, 0, 8) // 预分配容量 8

// Java: items.add("hello")
items = append(items, "hello")

// Java: for (String item : items) { ... }
for _, item := range items {
    fmt.Println(item)
}

// Java: Map<String, Integer> m = new HashMap<>();
m := make(map[string]int)

// Java: try { ... } catch (IOException e) { ... }
// Go: 显式返回 error
data, err := os.ReadFile("tasks.json")
if err != nil {
    // 必须处理，不能忽略
}

// Java: class Dog extends Animal implements Speaker { ... }
// Go: 组合 + 隐式接口
type Dog struct {
    Animal // 嵌入，不是继承
}
func (d Dog) Speak() string { return "Woof" } // 自动满足 Speaker 接口
```

---

## 阶段二：惯用思维（Week 4-6）

> **核心命题**：学会像 Go 程序员一样思考和编码，而不是用 Go 语法写 Java

### 阶段目标

- 掌握接口设计的 Go 式哲学（小接口、消费者定义）
- 建立 Go 的错误处理心智模型
- 写出可测试的代码（table-driven tests）
- 不依赖框架构建 HTTP API 服务

### 核心主题

1. **接口深度**
   - 接口隔离：**单方法接口最强大**（`io.Reader`、`io.Writer`、`fmt.Stringer`）
   - 接口定义在消费方，不是实现方 — 这是 Go 和 Java 最大的设计差异
   - `interface{}` / `any` 的类型断言 vs type switch
   - 接口值的底层结构：`(type, value)` 二元组，nil 接口 ≠ nil 具体类型

2. **错误处理模式**
   - Sentinel errors（`io.EOF`）+ `errors.Is()`
   - Custom error types + `errors.As()`
   - `fmt.Errorf("context: %w", err)` 错误包装
   - `errors.Join`（Go 1.20+）合并多个错误
   - **黄金法则**：每个错误只处理一次 — 要么记录，要么向上传，不要两样都做

3. **测试**
   - Table-driven tests：Go 测试的标准范式
   - `testing.T`、`t.Run()` 子测试、`t.Parallel()` 并行测试
   - Test fixtures：`testdata/` 目录约定
   - 表格测试 + 子测试 = Go 测试的全部，不需要 JUnit 那样的框架
   - `httptest.NewServer()` — 测试 HTTP handler 的标准方式

4. **标准库精要**
   - `net/http`：Handler 接口、ServeMux、中间件模式
   - `encoding/json`：struct tag、`Marshal`/`Unmarshal`、自定义序列化
   - `database/sql`：连接池、预编译语句、事务
   - `time`：时间处理的陷阱（monotonic vs wall clock）
   - `context`：请求作用域的值、取消信号、超时控制

5. **代码组织**
   - 项目布局惯例（不是官方标准，但社区广泛采用）
   - `cmd/`、`internal/`、`pkg/` 的语义
   - 依赖注入：构造函数传递，不用框架
   - 功能选项模式（Functional Options）：Go 里最优雅的配置模式

### 推荐资源

| 资源                                                                         | 用法                                  |
| ---------------------------------------------------------------------------- | ------------------------------------- |
| [_The Go Programming Language_](https://www.gopl.io/) 第 7、9、11、12 章 | 接口、并发基础、测试、反射 |
| [_Let's Go_](https://lets-go.alexedwards.net/)（Alex Edwards）| 手动构建一个完整 Web 应用，不依赖框架 |
| [Go Stdlib by Example](https://pkg.go.dev/std)                               | 官方标准库文档，从 `net/http` 开始读  |
| [_100 Go Mistakes_](https://www.manning.com/books/100-go-mistakes-and-how-to-avoid-them) 第 1-5 章 | 代码组织、类型、控制结构的常见坑 |
| [Dave Cheney: Go Error Handling](https://dave.cheney.net/tag/error-handling) | 错误处理的哲学深度文                  |
| [Testing in Go](https://go.dev/doc/tutorial/add-a-test)                      | 官方测试教程                          |

### 阶段项目：Gask — RESTful 任务管理 API

**目标**：在 Godo 的基础上，将待办事项暴露为 HTTP API，不依赖任何第三方 Web 框架。

```
POST   /tasks          → 创建任务
GET    /tasks          → 列出所有任务
GET    /tasks/{id}     → 获取单个任务
PUT    /tasks/{id}     → 更新任务
DELETE /tasks/{id}     → 删除任务
```

**技术要求**：

- 只用 `net/http`（不用 Gin/Chi/Echo）
- 自定义 `Handler` 实现路由分发（或使用 Go 1.22+ 的增强 `ServeMux`）
- 请求校验 + 结构化 JSON 错误响应 `{"error": "...", "code": "INVALID_INPUT"}`
- 分层架构：`handler → service → store`，通过构造函数注入
- **Table-driven tests**：每个 handler 至少 3 个测试用例（正常、边界、异常）
- 用 `httptest.NewServer()` 做集成测试
- 自定义错误类型，在 HTTP 层统一映射到状态码
- 使用 `context.Context` 传递请求级信息

**自检清单**：

- [ ] 为什么 Go 接口要定义在使用方而非实现方？
- [ ] `var r io.Reader = nil` 和 `var r io.Reader = (*os.File)(nil)` 区别是什么？
- [ ] `errors.Is` 和 `errors.As` 各用于什么场景？
- [ ] table-driven test 和 JUnit `@ParameterizedTest` 的根本区别是什么？
- [ ] 中间件在 Go 里是怎么实现的？（`http.Handler` 包装模式）

### Java ↔ Go 对比速查

```go
// Java: implements 是显式的
// Go: 接口自动满足 — 这是最核心的思维差异
type Store interface {
    Find(id string) (Task, error)
    Save(t Task) error
}

type JSONStore struct { path string }
func (s *JSONStore) Find(id string) (Task, error) { /* ... */ }
func (s *JSONStore) Save(t Task) error { /* ... */ }
// JSONStore 自动实现了 Store，无需声明

// Java: @Test void testFind() { ... }
// Go: table-driven test
func TestFind(t *testing.T) {
    tests := []struct {
        name    string
        id      string
        want    Task
        wantErr bool
    }{
        {"正常查找", "1", Task{ID: "1"}, false},
        {"不存在", "999", Task{}, true},
        {"空ID", "", Task{}, true},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := store.Find(tt.id)
            if (err != nil) != tt.wantErr {
                t.Errorf("Find() error = %v, wantErr %v", err, tt.wantErr)
            }
            if got != tt.want {
                t.Errorf("Find() = %v, want %v", got, tt.want)
            }
        })
    }
}

// Java: throws NotFoundException
// Go: 返回 error，由上层决定如何处理
if errors.Is(err, ErrNotFound) {
    w.WriteHeader(http.StatusNotFound)
    json.NewEncoder(w).Encode(ErrorResponse{...})
    return
}
```

---

## 阶段三：并发模型（Week 7-9）

> **核心命题**：学会 Go 的 CSP 并发哲学，用 goroutine 和 channel 解决实际问题

### 阶段目标

- 理解 Go 的内存模型和 goroutine 调度
- 掌握 channel 的惯用模式（所有权、方向、关闭）
- 熟练使用 `sync` 包和 `context` 包
- 能诊断和修复 goroutine 泄漏和竞态条件

### 核心主题

1. **Goroutine 基础**
   - `go` 关键字：启动一个轻量级协程（不是线程！）
   - GMP 调度模型简析：G（goroutine）、M（machine/OS线程）、P（processor）
   - Goroutine 栈是动态伸缩的（从 2KB 开始），与 JVM 线程的固定栈完全不同
   - **永远不要在不知道谁负责停止的情况下启动 goroutine**

2. **Channel**
   - 无缓冲 vs 有缓冲 channel
   - Channel 方向（`chan<-` 只写，`<-chan` 只读）
   - 关闭 channel 的语义：**只有发送方才能关闭**
   - `for range` 遍历 channel（自动在关闭时退出）
   - `select` 多路复用
   - `nil` channel 在 `select` 中永远不被选中 — 这是有用的模式

3. **同步原语**
   - `sync.Mutex` / `sync.RWMutex`
   - `sync.WaitGroup`：等待一组 goroutine 完成
   - `sync.Once`：确保只执行一次
   - `sync/atomic`：无锁的原子操作
   - `errgroup.Group`：并发的错误处理（`golang.org/x/sync/errgroup`）

4. **Context 包**
   - `context.WithCancel` / `WithTimeout` / `WithDeadline`
   - Context 在整个调用链中传递取消信号
   - **不要把 context 存到 struct 里** — 这是 Java 的习惯，Go 里 context 是显式传递的
   - Context values：用于请求级数据（trace ID、user info），不是依赖注入容器

5. **并发模式**
   - Pipeline 模式：`gen → process → output`
   - Fan-out / Fan-in：分散处理，汇聚结果
   - Worker pool：用 channel 控制并发度
   - Or-Done 模式：组合多个取消信号
   - **原则**：“不要通过共享内存来通信，通过通信来共享内存”

6. **调试与诊断**
   - Race detector：`go test -race`、`go run -race`
   - `pprof` goroutine profile：检测泄漏
   - `runtime.NumGoroutine()` 在测试中使用

### 推荐资源

| 资源                                                                           | 用法                                   |
| ------------------------------------------------------------------------------ | -------------------------------------- |
| [_Concurrency in Go_](https://www.oreilly.com/library/view/concurrency-in-go/9781491941294/)（Katherine Cox-Buday） | 精读全书，这是 Go 并发领域最好的书 |
| [_The Go Programming Language_](https://www.gopl.io/) 第 8-9 章 | goroutine、channel、基于共享变量的并发 |
| [_100 Go Mistakes_](https://www.manning.com/books/100-go-mistakes-and-how-to-avoid-them) 第 8-9 章 | goroutine 泄漏、context 误用 |
| [Go Concurrency Patterns (Slide)](https://go.dev/talks/2012/concurrency.slide) | Rob Pike 的经典演讲                    |
| [Go Concurrency Patterns: Pipelines](https://go.dev/blog/pipelines)            | Go Blog 经典文章                       |
| [Go Memory Model](https://go.dev/ref/mem)                                      | 必读，理解 happens-before 关系         |

### 阶段项目：GoCrawl — 并发网页爬虫

**目标**：实现一个并发爬虫，从种子 URL 开始，递归抓取同域名下的页面并提取标题和链接。

```
$ gocrawl --depth=3 --concurrency=10 https://gobyexample.com/
  https://gobyexample.com/              → "Go by Example"
    https://gobyexample.com/hello-world → "Hello World"
    https://gobyexample.com/values      → "Values"
    ...
  抓取完成: 42 个页面, 耗时 1.3s
```

**技术要求**：

- 使用 goroutine 并发抓取，通过 buffered channel 或 semaphore 控制并发数
- 用 `context.WithTimeout` 设定整体超时（防止无限运行）
- 用 `context.WithCancel` 支持 Ctrl+C 优雅退出
- Channel 用于传递抓取结果和工作任务
- 用 `sync.WaitGroup` 等待所有 worker 结束
- 去重：用 `map[string]bool` + `sync.Mutex` 保护（思考：能否用 channel 替代？）
- 遵守 `robots.txt`
- 编写带有 `-race` 标志的测试，确保没有竞态条件
- 用 benchmark 测试不同并发度的性能差异

**自检清单**：

- [ ] 什么时候用 channel，什么时候用 mutex？
- [ ] 为什么"发送方关闭 channel"是规则？接收方关闭会怎样？
- [ ] `select` 中多个 case 同时就绪时，如何选择？这对公平性意味着什么？
- [ ] goroutine 泄漏的典型场景有哪些？如何用 pprof 定位？
- [ ] context 取消信号是如何向下游传播的？中间件要怎么写才对？

### Java ↔ Go 对比速查

```go
// Java: ExecutorService executor = Executors.newFixedThreadPool(10);
//       Future<String> future = executor.submit(() -> fetch(url));
// Go: 用 goroutine + channel 替代线程池
resultCh := make(chan Result, 10) // buffered，防止 worker 阻塞
sem := make(chan struct{}, 10)    // semaphore 控制并发度

for _, url := range urls {
    sem <- struct{}{} // 获取令牌
    go func(url string) {
        defer func() { <-sem }() // 释放令牌
        // 抓取逻辑
        resultCh <- Result{URL: url, Title: title}
    }(url) // 注意：循环变量必须作为参数传入！
}
// ❌ Java 习惯：在循环里直接引用循环变量
// ✅ Go 习惯：把循环变量作为 goroutine 参数传入

// Java: CountDownLatch
// Go: sync.WaitGroup
var wg sync.WaitGroup
for _, url := range urls {
    wg.Add(1)
    go func(url string) {
        defer wg.Done()
        // 抓取逻辑
    }(url)
}
wg.Wait()

// Java: try { executor.awaitTermination(10, SECONDS); } catch (InterruptedException e) {}
// Go: context 超时
ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
defer cancel()
select {
case <-ctx.Done():
    return ctx.Err()
case result := <-resultCh:
    // 处理结果
}
```

---

## 阶段四：生产级 Go（Week 10-12）

> **核心命题**：把前三阶段的技能整合为一个生产就绪的服务，建立从开发到部署的完整认知

### 阶段目标

- 掌握 Go 项目的标准架构和依赖注入
- 集成数据库、配置管理、可观测性
- 能写出内存高效、GC 友好的代码
- 交付一个容器化、可部署的 Go 服务

### 核心主题

1. **项目架构**
   - Clean Architecture 在 Go 中的落地（不是 Spring 的分层，而是依赖反转）
   - `cmd/` + `internal/` + 功能包的结构
   - 依赖注入：Wire（编译时）vs 手动构造函数 vs Fx（运行时容器）
   - 配置管理：Viper + 环境变量 + 配置文件
   - 功能选项模式（Functional Options）用于配置

2. **数据库**
   - `database/sql` + `sqlx` 或 `pgx`
   - 迁移工具：`golang-migrate`、`atlas`
   - SQL 代码生成：`sqlc` — 从 SQL 生成类型安全的 Go 代码（推荐先试这个）
   - 事务管理：通过 `context.Context` 传递事务
   - 连接池调优：`SetMaxOpenConns`、`SetMaxIdleConns`、`SetConnMaxLifetime`

3. **可观测性**
   - 结构化日志：`log/slog`（Go 1.21+ 内置）
   - 指标：Prometheus client + `expvar`
   - 分布式追踪：OpenTelemetry 集成
   - HTTP 中间件：自动记录每个请求的延迟、状态码、trace ID

4. **性能意识**
   - 逃逸分析：理解什么分配在栈上 vs 堆上 — `go build -gcflags="-m"`
   - `strings.Builder` vs `+` vs `fmt.Sprintf`
   - Pre-allocation：`make([]T, 0, capacity)`
   - `sync.Pool` 复用临时对象
   - Benchmark：`go test -bench=. -benchmem`
   - pprof：CPU profile、memory profile、goroutine profile

5. **部署**
   - 多阶段 Docker build + distroless 基础镜像（最终镜像 < 20MB）
   - 优雅关闭：收到 SIGTERM → 停止接受新请求 → 等待现有请求完成 → 退出
   - 健康检查：`/health`（liveness）+ `/ready`（readiness）
   - Makefile 标准化：`build`、`test`、`lint`、`run`

### 推荐资源

| 资源                                                                                   | 用法                                                     |
| -------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| [_Let's Go Further_](https://lets-go-further.alexedwards.net/)（Alex Edwards） | 生产级 JSON API，涵盖 auth、CORS、metrics、rate limiting |
| [_100 Go Mistakes_](https://www.manning.com/books/100-go-mistakes-and-how-to-avoid-them) 第 10-12 章 | 标准库误用、优化、可观测性 |
| [_Efficient Go_](https://www.oreilly.com/library/view/efficient-go/9781098105709/)（Płotka & Branczyk） | 生产环境的性能优化和 SLO 驱动开发 |
| [Cloud Native Go](https://www.oreilly.com/library/view/cloud-native-go/9781492076339/) | 云原生实践                                               |
| [Go 项目布局讨论](https://go.dev/doc/modules/layout)                                   | 官方的模块布局指南（先读这个再看社区标准）               |
| [Docker 官方 Go 镜像指南](https://docs.docker.com/language/golang/)                    | 多阶段构建最佳实践                                       |

### 阶段项目：GoDash — 微型可观测仪表板

**目标**：整合前三个阶段的所有技能，构建一个带有 Web Dashboard 的系统指标监控服务。

```
架构概览：

┌─────────────┐    ┌─────────────┐    ┌──────────┐
│  Collector  │───▶│   PostgreSQL │◀───│  API     │
│  (goroutine)│    │   (Timescale)│    │  Server  │
└─────────────┘    └─────────────┘    └────┬─────┘
       │                                    │
 采集 CPU/Mem/...                    ┌──────┴──────┐
                                     │  Web UI     │
                                     │  (embed FS) │
                                     └─────────────┘
```

**技术要求**：

- **Collector**：用 goroutine 定时采集系统指标（CPU、内存、磁盘、网络），写入 PostgreSQL
- **API Server**：RESTful API 查询历史指标数据，支持时间范围和聚合
- **Web UI**：用 `embed` 将前端静态文件编译进二进制（单文件部署）
- **数据库**：用 `sqlc` 从 SQL 生成 Go 代码，`golang-migrate` 管理 schema
- **配置**：用环境变量 + YAML 配置文件（Viper），不要硬编码
- **可观测性**：slog 结构化日志 + Prometheus metrics endpoint (`/metrics`)
- **优雅关闭**：SIGTERM/SIGINT 停止采集器 → 等待 HTTP 请求完成 → 关闭 DB 连接
- **Docker**：多阶段构建（`golang:alpine` 编译 + `distroless` 运行），最终镜像 < 25MB
- **测试**：单元测试 + 集成测试（用 testcontainers-go 拉起 PostgreSQL）
- **Lint**：`golangci-lint` 配置，CI 通过才算成功

**自检清单**：

- [ ] 你的服务收到 SIGTERM 后多久才能安全退出？能保证不丢数据吗？
- [ ] `context.Context` 在数据库操作中扮演什么角色？
- [ ] 连接池的默认值是多少？你的并发量和数据库的最大连接数匹配吗？
- [ ] 为什么 Go 的 Docker 镜像可以这么小？`FROM scratch` 的前提条件是什么？
- [ ] 逃逸分析显示你的热路径代码有没有不必要的堆分配？

### Java ↔ Go 对比速查

```go
// Java: Spring Boot application.properties + @Value
// Go: Viper + 环境变量
viper.SetConfigName("config")
viper.SetConfigType("yaml")
viper.AddConfigPath(".")
viper.AutomaticEnv()
if err := viper.ReadInConfig(); err != nil {
    // config file is optional
}
port := viper.GetString("server.port")

// Java: @Autowired + @Component
// Go: 手动构造函数注入（或 Wire）
func NewServer(repo Repository, logger *slog.Logger) *Server {
    return &Server{repo: repo, log: logger}
}

// Java: @Scheduled(fixedRate = 5000)
// Go: goroutine + time.Ticker
go func() {
    ticker := time.NewTicker(5 * time.Second)
    defer ticker.Stop()
    for {
        select {
        case <-ticker.C:
            collectMetrics(ctx)
        case <-ctx.Done():
            return // 响应取消，退出 goroutine
        }
    }
}()

// Java: @PreDestroy
// Go: 优雅关闭
sigCh := make(chan os.Signal, 1)
signal.Notify(sigCh, syscall.SIGTERM, syscall.SIGINT)
<-sigCh
// 开始优雅关闭...
```

---

## 长期进阶方向

完成四个阶段后，你已经是合格的生产级 Go 开发者。以下是可选的精进方向：

| 方向                  | 内容                                                                      | 起点                                                                                     |
| --------------------- | ------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| **Go 编译器与运行时** | 学习 Go 编译器的 SSA 后端、逃逸分析算法、GC 实现细节                      | [Go 编译器源码](https://github.com/golang/go/tree/master/src/cmd/compile) 的注释非常清晰 |
| **eBPF / 内核编程**   | 用 Go 写 eBPF 程序（cilium/ebpf），做网络观测和安全                       | [cilium/ebpf](https://github.com/cilium/ebpf)                                            |
| **分布式系统**        | Raft 共识、gRPC 流式、事件溯源、CQRS                                      | HashiCorp 的 [Raft 库](https://github.com/hashicorp/raft)                                |
| **WASM / 边缘计算**   | 用 Go 编译到 WebAssembly，在浏览器或边缘节点运行                          | [TinyGo](https://tinygo.org/)                                                            |
| **语言贡献**          | 阅读 Go 提案流程，向标准库贡献代码                                        | [Go 提案流程](https://go.dev/s/proposal)                                                 |
| **源码阅读计划**      | 精读 `net/http`、`encoding/json`、`sync` 的源码 — Go 标准库是最好代码范例 | 从 `io.Reader` 开始                                                                      |

---

## 附录

### A. 常用命令速查

```bash
# 项目初始化
go mod init github.com/yourname/project    # 创建模块
go mod tidy                                # 清理依赖
go mod download                            # 下载依赖到本地缓存

# 编译与运行
go build -o bin/app ./cmd/server           # 编译
go run ./cmd/server                        # 编译并运行（开发用）
GOOS=linux GOARCH=amd64 go build          # 交叉编译
go build -ldflags="-s -w"                 # 减小二进制体积（strip）

# 测试
go test ./...                              # 运行所有测试
go test -v -race ./...                     # 详细输出 + 竞态检测
go test -coverprofile=coverage.out ./...   # 覆盖率
go tool cover -html=coverage.out           # 覆盖率可视化
go test -bench=. -benchmem                 # 运行 benchmark

# 代码质量
go fmt ./...                               # 格式化所有代码
go vet ./...                               # 静态分析（可疑代码检查）
golangci-lint run                          # 全功能 linter（需安装）
go mod verify                              # 验证依赖完整性

# 性能分析
go test -cpuprofile=cpu.prof -bench=.     # CPU profile
go tool pprof -http=:8080 cpu.prof         # 可视化 pprof
go build -gcflags="-m"                    # 查看逃逸分析结果
```

### B. Go 工具链全景

```
go               # Go 工具入口
├── bug          # 提交 bug 报告
├── build        # 编译包和依赖
├── clean        # 清理构建产物
├── doc          # 查看文档（godoc 替代）
├── env          # 打印 Go 环境变量
├── fix          # 更新旧代码到新 API
├── fmt          # 格式化代码
├── generate     # 运行代码生成器（//go:generate）
├── get          # 添加依赖
├── install      # 编译并安装到 $GOPATH/bin
├── list         # 列出包/模块
├── mod          # 模块管理子命令
│   ├── init     # 初始化 go.mod
│   ├── tidy     # 修剪依赖
│   ├── download # 下载模块到缓存
│   ├── vendor   # 创建 vendor 目录
│   ├── verify   # 验证依赖
│   ├── why      # 解释为什么需要某个依赖
│   └── graph    # 打印模块依赖图
├── run          # 编译并运行
├── test         # 测试
├── tool         # 运行指定工具（pprof、trace、compile 等）
├── version      # Go 版本
└── vet          # 报告可疑代码
```

### C. 必备第三方工具

```bash
# 安装（不在 go.mod 里，全局安装）
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest  # Linter
go install golang.org/x/tools/cmd/goimports@latest                     # 自动 format + import
go install honnef.co/go/tools/cmd/staticcheck@latest                   # 高级静态分析
go install github.com/go-task/task/v3/cmd/task@latest                  # Makefile 替代
go install github.com/air-verse/air@latest                             # 热重载（开发用）
```

### D. 社区与持续学习

| 渠道                                                       | 说明                                 |
| ---------------------------------------------------------- | ------------------------------------ |
| [r/golang](https://reddit.com/r/golang)                    | Reddit Go 社区，新版本讨论和项目分享 |
| [Gophers Slack](https://invite.slack.golangbridge.org/)    | 最大的 Go 即时讨论社区               |
| [Go Weekly](https://golangweekly.com/)                     | 每周邮件精选                         |
| [Go Time Podcast](https://changelog.com/gotime)            | Go 技术播客                          |
| [GopherCon Talks](https://www.youtube.com/c/GopherAcademy) | 年度 GopherCon 演讲视频              |

---

> **最后的建议**：12 周后，不要停在这里。找一个问题去解决——工作中的内部工具、开源项目的 Good First Issue、或者一个困扰你很久的个人痛点——用 Go 去实现它。**语言是在解决问题中真正学会的，不是在阅读路线图中学会的。**
