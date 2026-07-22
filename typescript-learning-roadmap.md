# TypeScript 学习路线图：系统进阶

> **学习周期**：12 周（每周 10-15 小时）
> **最终产出**：能独立设计并交付生产级全栈 TypeScript 应用

---

## 前言：TypeScript 核心概念

在开始学习之前，先理解 TypeScript 在**设计哲学**上的关键特性。这比你记住语法细节更重要。

| 特性           | 说明                                                                    |
| -------------- | ----------------------------------------------------------------------- |
| **核心理念**   | 多范式融合（FP+OOP），实用优先，类型为设计服务                          |
| **类型系统**   | Structural typing（结构决定类型，鸭子类型）                             |
| **类型推导**   | 全语言深度推导，类型体操是常态                                          |
| **空值处理**   | `strictNullChecks` + Union Types，编译期拦截                            |
| **错误处理**   | try-catch + Promise rejection，无受检异常                               |
| **异步模型**   | 事件循环 + Promise/async-await（单线程并发）                            |
| **运行时**     | JavaScript 引擎（V8/SpiderMonkey），类型被擦除                          |
| **依赖管理**   | npm/yarn/pnpm + node_modules（海量生态）                                |
| **框架文化**   | 百花齐放：Next.js / NestJS / Express / Fastify                          |
| **泛型**       | 一等公民，支持条件类型、映射类型、模板字面量类型                        |
| **访问控制**   | `public`/`private`/`protected`（编译期 only）+ `#privateField`（运行时）|
| **构建产物**   | .ts → .js → bundle → tree-shake → minify                                |
| **编译器**     | **tsc 7.0+ 用 Go 重写**（Project Corsa），性能提升 ~10x                 |
| **模块系统**   | ESM / CJS 双模块系统                                                    |

**最重要的核心理念**：

1. **TypeScript 的类型在运行时全部消失** — "你能通过类型表达意图，编译器帮你检查，但运行时你得自己兜底"
2. **拥抱 Structural Typing** — 不需要 `implements`，结构匹配就是类型匹配。这和 Go 的隐式接口一样，但更激进
3. **异步不是多线程** — JavaScript 是单线程事件循环。`async/await` 是语法糖，底层是 Promise 微任务队列，不是线程调度
4. **npm 生态是双刃剑** — 你能找到一切，但质量参差不齐。学会审计依赖、锁定版本、最小化依赖
5. **理解 Node.js 的中间件模式** — "洋葱模型"是 Node.js 服务端架构的核心思想
6. **TypeScript 7.0 编译器是用 Go 写的**（Project Corsa）——2025 年底公开预览，2026 年 7 月正式 GA。编译和类型检查速度提升 ~10 倍，内存占用降低 ~25%

---

## 阶段一：基础语感（Week 1-3）

> **核心命题**：在 JavaScript 的语义上建立 TypeScript 的类型肌肉记忆

### 阶段目标

- 用 TypeScript 写出结构清晰的小程序（Node.js 环境）
- 理解 TypeScript 的类型系统、`tsconfig.json`、模块机制
- 能独立配置 TypeScript 项目并管理 npm 依赖
- 区分"JavaScript 语义"和"TypeScript 类型层面"的边界

### 核心主题

1. **环境与工具链**
   - Node.js 安装与版本管理（`nvm` / `fnm`）
   - npm / yarn / pnpm 的选择与使用
   - **TypeScript 7.0+（2026 年 7 月 GA）**：编译器用 Go 重写（Project Corsa），类型检查速度提升 ~10x
     - 安装：`npm install -D typescript`（仍然是 npm 包，但二进制是 Go 编译的）
     - 新 CLI 参数：`--checkers`（并行类型检查线程数）、`--builders`（并行构建线程数）
     - 与 6.x 向后兼容：如遇问题可降级到 `@typescript/typescript6` 包
   - `tsconfig.json` 核心配置：`target`、`module`、`strict`、`outDir`、`rootDir`、`include`
   - `tsc --noEmit` 仅类型检查（不输出 JS，CI 必备。7.0 后快 10 倍！）
   - 关键命令：`tsc`、`ts-node` / `tsx`、`node --experimental-strip-types`（Node 22+）
   - **ESLint + Prettier**：TypeScript 世界的 `gofmt` 等价物

2. **基础类型**
   - 原始类型：`string`、`number`、`boolean`、`symbol`、`bigint`
   - 特殊类型：`null`、`undefined`、`void`、`never`、`unknown`
   - `any` vs `unknown`：`any` 是逃生舱，`unknown` 是"我不知道类型但我会检查"
   - 数组与元组：`T[]` vs `[string, number]`（定长、定类型）
   - `enum` vs Union Types：**优先用 Union Types，除非你需要反向映射**
   - 字面量类型：`type Direction = "left" | "right"` 比传统 enum 更灵活

3. **变量与控制流**
   - `let` vs `const`：`const` 是"引用不可变"不是"值不可变"
   - **没有 `var`** — 它存在但永远不要用（函数作用域 + 提升，陷阱无数）
   - `if`、`for`、`while`、`switch` — 类 C 语法，直觉友好
   - `for...of` + `for...in`（前者遍历值，后者遍历键 — 容易搞混）
   - **Falsy 值**：`0`、`""`、`null`、`undefined`、`NaN`、`false` — 这是个坑

4. **函数**
   - 函数声明 vs 函数表达式 vs 箭头函数
   - 箭头函数 ≠ lambda：没有自己的 `this`，没有 `arguments` 对象
   - 参数解构 + 默认值：`function fetch({ url, method = "GET" }: FetchOptions)`
   - 剩余参数：`...args: string[]`
   - **函数重载**：声明签名 + 实现签名（只有一个实现体）
   - `this` 的类型标注

5. **对象与接口**
   - Object 字面量类型：`{ name: string; age: number }`
   - `interface` vs `type`：优先 `interface`（可合并声明），需要联合/交叉/映射类型时用 `type`
   - 可选属性：`age?: number`
   - 只读属性：`readonly id: string`
   - 索引签名：`[key: string]: unknown`
   - `Record<K, V>` 工具类型

6. **类（Class）**
   - 类的语法基于 ES6 class，有 TypeScript 特有的类型增强
   - `public` / `private` / `protected`（只在编译期存在，运行时全公开）
   - **ECMAScript `#privateField`** (真正的运行时私有) vs `private` 关键字
   - 参数属性：`constructor(private name: string)` — 一行搞定声明+赋值
   - `readonly`、`abstract`、`static`
   - **不鼓励过度使用类**：优先用普通函数 + 闭包 + 纯数据结构

7. **模块系统**
   - ESM（`import` / `export`）是现代标准
   - CJS（`require` / `module.exports`）仍然大量存在
   - `export default` vs named export：优先 named export（更好的 tree-shaking + 重构支持）
   - 路径别名：`tsconfig.json` 的 `paths` + `@/` 模式
   - `package.json` 的 `"type": "module"` 和 `.mts` / `.cts` 扩展名

### 推荐资源

| 资源                                                                           | 用法                                                 |
| ------------------------------------------------------------------------------ | ---------------------------------------------------- |
| [TypeScript 官方手册](https://www.typescriptlang.org/docs/handbook/intro.html) | 精读前 5 章（基础类型 → 对象类型），2-3 天完成       |
| [Total TypeScript Beginners](https://www.totaltypescript.com/)（Matt Pocock）  | 免费教程质量极高，按主题学习                         |
| [TypeScript 练习场](https://www.typescriptlang.org/play/)                      | 随手测试类型行为，比写文件快                         |
| [_Effective TypeScript_](https://effectivetypescript.com/) 第 1-3 章           | Dan Vanderkam 的经典，第 1 章是必读                  |
| [JavaScript 高级程序设计](https://www.ituring.com.cn/book/2472) 第 3-6、10 章  | 补齐 JS 基础：作用域、引用类型、函数、Promise        |
| [Node.js 官方入门](https://nodejs.org/en/learn/)                               | 理解 Node.js 运行时：fs、path、process、EventEmitter |

### 阶段项目：Taskly — CLI 任务管理器

**目标**：用 TypeScript + Node.js 实现一个命令行任务管理器，纯标准库。

```
$ npx tsx taskly.ts add "读完 Effective TypeScript 第3章"
  ✓ 已添加任务 #1: 读完 Effective TypeScript 第3章

$ npx tsx taskly.ts list
  #1 [ ] 读完 Effective TypeScript 第3章
  #2 [✓] 安装配置 ESLint + Prettier
  #3 [ ] 理解 TypeScript 的 Structural Typing

$ npx tsx taskly.ts done 1
  ✓ 完成任务 #1

$ npx tsx taskly.ts delete 2
  ✓ 已删除任务 #2

$ npx tsx taskly.ts list --filter=pending
  #1 [✓] 读完 Effective TypeScript 第3章
  #3 [ ] 理解 TypeScript 的 Structural Typing
```

**技术要求**：

- 用 `process.argv` 解析命令行参数（或 `commander` 库）
- 用 JSON 文件持久化（`fs.readFileSync` / `fs.writeFileSync`）
- 定义清晰的类型：`Task`、`TaskStatus`、`Command`、`CLIOptions`
- 合理拆分模块：`types.ts`、`storage.ts`、`commands.ts`、`cli.ts`
- 错误处理：文件不存在则创建，JSON 解析失败则提示
- `tsconfig.json` 配置 `strict: true`

**自检清单**：

- [ ] `const arr: readonly number[] = [1,2,3]` — `arr.push(4)` 会报什么错？这个 readonly 在运行时还存在吗？
- [ ] `interface` 和 `type` 的核心区别是什么？什么时候必须用 `type`？
- [ ] `unknown` 和 `any` 的区别？为什么应该优先用 `unknown`？
- [ ] `"strict": true` 包含了哪些子选项？为什么 TypeScript 不是默认 strict 的？
- [ ] `for...of` 和 `for...in` 各遍历什么？写一个例子确认你记对了

---

## 阶段二：类型系统深度（Week 4-6）

> **核心命题**：掌握 TypeScript 的类型编程能力，用类型表达业务约束，而不是仅用类型标注

### 阶段目标

- 理解 TypeScript 的高级类型特性（泛型、条件类型、映射类型）
- 能读懂开源库的 `.d.ts` 类型定义
- 掌握函数重载和类型谓词
- 建立 Zod/io-ts 等运行时校验的认知（类型擦除的补救措施）

### 核心主题

1. **泛型（Generics）**
   - 泛型函数：`function identity<T>(arg: T): T`
   - 泛型约束：`<T extends HasId>` — 约束类型参数必须满足某个结构
   - 泛型默认值：`<T = string>`
   - 泛型推断：不需要显式传类型参数，TypeScript 自动推导
   - **泛型在运行时被完全擦除** — TypeScript 的类型推导能力极强，泛型参数通常可以自动推断
   - 最佳实践：**让你的泛型代表实际存在的东西**（不要造出"抽象类型参数"然后把 `any` 传进去）

2. **Union Types & 类型收窄（Narrowing）**
   - 字面量 Union：`type Status = "active" | "inactive" | "pending"`
   - **Discriminated Unions**（有标签的联合类型）：TypeScript 最强大的模式之一
     ```typescript
     type Shape =
       | { kind: "circle"; radius: number }
       | { kind: "rectangle"; width: number; height: number };
     ```
   - 类型守卫：`typeof`、`instanceof`、`in`、自定义类型谓词 `arg is T`
   - Exhaustiveness checking：用 `never` 确保 switch 覆盖所有分支

3. **条件类型（Conditional Types）**
   - `T extends U ? X : Y` — 类型层面的三元运算符
   - `infer` 关键字：在条件类型中提取类型变量
   - 分布式条件类型：`T extends U` 在 T 是联合类型时的行为
   - 实用模式：提取 Promise 的 resolved 类型、提取函数返回类型、提取数组元素类型

4. **映射类型（Mapped Types）**
   - 基础语法：`{ [K in keyof T]: NewType }`
   - 内置工具类型：`Partial<T>`、`Required<T>`、`Readonly<T>`、`Pick<T, K>`、`Omit<T, K>`
   - `keyof` 运算符：获取对象类型的所有键
   - `as` 子句：键重映射
   - 模板字面量类型：`` type EventName = `on${Capitalize<string>}` ``

5. **类型体操进阶**
   - `ts-reset`：修复 TypeScript 标准库的类型缺陷
   - 递归类型：定义树形结构、JSON 类型等
   - 品牌类型（Branded Types / Opaque Types）：区分语义相同但意义不同的原始类型
   - `satisfies` 运算符（TS 4.9+）：检查类型但不改变推导
   - `const` 断言：`as const` — 把值变成字面量类型

6. **运行时校验**
   - **类型在运行时消失** — 这是 TypeScript 最容易被忘记的事实
   - Zod：定义 schema → 自动推导 TypeScript 类型 + 运行时校验
   - io-ts / valibot / typia（编译期生成校验代码）
   - 何时需要运行时校验：API 响应、用户输入、文件内容、环境变量

7. **模块声明**
   - `.d.ts` 文件的作用和编写
   - `declare module` / `declare global` / `declare namespace`
   - 为没有类型的 JS 库写声明文件
   - `*.d.ts` 的三斜线指令（现在基本不需要了）

### 推荐资源

| 资源                                                                                                            | 用法                                        |
| --------------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| [TypeScript 类型挑战](https://github.com/type-challenges/type-challenges)                                       | 从 Easy 开始，做到 Medium 即可              |
| [TypeScript 官方手册 - Type Manipulation](https://www.typescriptlang.org/docs/handbook/2/types-from-types.html) | 精读泛型、keyof、typeof、条件类型、映射类型 |
| [_Effective TypeScript_](https://effectivetypescript.com/) 第 4-5 章                                            | 类型设计和 any 的处理                       |
| [Type-Level TypeScript](https://type-level-typescript.com/)                                                     | 类型体操训练营                              |
| [Zod 官方文档](https://zod.dev/)                                                                                | 读完 Quick Start + 理解 refine/transform    |
| [Matt Pocock 的 YouTube](https://www.youtube.com/@mattpocockuk)                                                 | 类型技巧，5-10 分钟一个，每天看一个         |

### 阶段项目：Taskly API — 强类型 Express/NestJS API

**目标**：在 CLI 版基础上，将任务管理暴露为 HTTP API，重点练习类型设计。

```
POST   /api/tasks           → 创建任务（Zod 校验输入）
GET    /api/tasks            → 列出任务（支持 ?status= & ?page= & ?limit= 分页查询）
GET    /api/tasks/:id        → 获取单个任务
PATCH  /api/tasks/:id        → 部分更新任务
DELETE /api/tasks/:id        → 删除任务
```

**技术要求**：

- 使用 Express（或 Fastify）搭建 HTTP 服务
- 用 Zod 定义所有 API 的请求/响应 schema
- 从 Zod schema 推导 TypeScript 类型：`type CreateTaskInput = z.infer<typeof createTaskSchema>`
- 实现 Discriminated Union 的 API 响应类型：
  ```typescript
  type ApiResponse<T> =
    | { success: true; data: T }
    | { success: false; error: { code: string; message: string } };
  ```
- 分页参数的范型封装：`PaginationParams`、`PaginatedResponse<T>`
- 中间件模式：请求日志、错误处理、请求校验（Zod middleware）
- 用 `tsx --watch` 实现热重载开发

**自检清单**：

- [ ] `Partial<T>` 和 `Required<T>` 的内部实现长什么样？你能手写吗？
- [ ] 什么场景下必须用 `declare` 关键字？
- [ ] Discriminated Union 的优势是什么？如何在 switch 中做 exhaustiveness check？
- [ ] Zod 的 `z.infer<typeof schema>` 和 TypeScript 的 `type MyType = ...` 是什么关系？运行时还存在 Zod schema 吗？
- [ ] 为什么 Node.js 的 API 需要 Zod/运行时校验，而 Go 不需要？


---

## 阶段三：异步编程与全栈 TypeScript（Week 7-9）

> **核心命题**：掌握异步 TypeScript 的全栈心智模型，从数据库到浏览器的事件循环都跑着同一个语言

### 阶段目标

- 深入理解 JavaScript 的事件循环和异步模型
- 熟练使用 Promise、async/await、流式处理
- 掌握 React/Next.js 前端开发（或你选择的前端框架）
- 端到端的类型共享：从数据库 schema 到 API 响应到前端组件 Props

### 核心主题

1. **事件循环深度**
   - 调用栈 → 宏任务（setTimeout/setInterval/I/O）→ 微任务（Promise.then/queueMicrotask）
   - **单线程 ≠ 不能并发**：Node.js 的 libuv 线程池处理 I/O，主线程处理你的代码
   - `process.nextTick()` vs `setImmediate()` vs `Promise.resolve().then()`
   - 事件循环阻塞：一个 CPU 密集操作会让整个服务停止响应
   - Worker Threads：真正的多线程（web-worker 在 Node 中的等价物）

2. **Promise 与 Async/Await**
   - Promise 的三态：pending → fulfilled / rejected（不可逆）
   - `.then()` / `.catch()` / `.finally()` 链式调用
   - `Promise.all()` / `Promise.allSettled()` / `Promise.race()` / `Promise.any()`
   - **`async/await` 是 Generator + Promise 的语法糖**
   - 常见陷阱：`forEach` 里用 `await` 不会等待（你中招过吗？）
   - 错误处理：`try/catch` 在 async 函数中、`.catch()` 在 Promise 链中
   - 并发控制：`p-limit`、`Promise.all` + chunking

3. **后端进阶（Node.js）**
   - Express / Fastify / Hono：HTTP 框架的选择
   - Prisma：TypeScript-first 的 ORM（类型从 schema 自动生成）
   - Drizzle ORM：更轻量、更 SQL-like 的选择
   - 数据库迁移：Prisma Migrate / Drizzle Kit
   - 中间件模式深度：洋葱模型（Koa/Redux 风格）
   - **tRPC**：端到端类型安全的 API（不需要 REST/GraphQL，直接共享类型）
   - 认证：JWT + 中间件 + `req.user` 类型扩展

4. **前端基础（React + TypeScript）**
   - 组件 Props 类型：`interface ButtonProps { ... }`
   - Hook 类型：`useState<Type>`、`useRef<HTMLInputElement>`、自定义 Hook 的范型
   - Event Handler 类型：`React.MouseEvent`、`React.ChangeEvent<HTMLInputElement>`
   - `React.FC` vs 普通函数：**推荐普通函数 + 显式 Props 类型**
   - Context API 的类型安全用法
   - `forwardRef` + `useImperativeHandle` 的类型

5. **全栈类型共享**
   - Monorepo 中共享类型包：`packages/shared-types/`
   - 从 Prisma/Drizzle schema 自动生成类型，贯穿全栈
   - tRPC 的哲学：Database → Router → Client，类型自动传播
   - 前后端共享 Zod schema
   - 类型安全的 API 调用：没有"忘记更新前端类型"这种事

6. **流式处理**
   - Node.js Streams：Readable / Writable / Transform
   - Async Iterators：`for await (const chunk of stream)`
   - Web Streams API（浏览器 + Node 18+）
   - Server-Sent Events（SSE）的类型处理
   - 文件处理：`fs.createReadStream` + pipeline

### 推荐资源

| 资源                                                                             | 用法                                    |
| -------------------------------------------------------------------------------- | --------------------------------------- |
| [JavaScript Visualized: Event Loop](https://www.youtube.com/watch?v=eiC58R16hb8) | 事件循环的最佳可视化讲解，必看          |
| [Node.js 设计模式](https://www.nodejsdesignpatterns.com/) 第 1-5 章              | 异步模式、流、观察者模式                |
| [Prisma 官方教程](https://www.prisma.io/docs/getting-started)                    | 从头到尾走一遍                          |
| [tRPC 官方文档](https://trpc.io/docs)                                            | 理解端到端类型安全的思想                |
| [React TypeScript Cheatsheet](https://react-typescript-cheatsheet.netlify.app/)  | 随查随用，React + TS 的所有常见类型问题 |
| [Total TypeScript — React with TypeScript](https://www.totaltypescript.com/)     | Matt Pocock 的 React TS 教程            |
| [Epic React](https://epicreact.dev/)（Kent C. Dodds）                            | 进阶 React 模式                         |

### 阶段项目：Taskly Fullstack — 全栈任务管理应用

**目标**：构建一个全栈 TypeScript 应用，重点是端到端的类型安全。

```
┌────────────────────────────────────────────────┐
│                    Browser                      │
│  ┌──────────────────────────────────────────┐  │
│  │  React (or Next.js)                      │  │
│  │  ┌─────────┐ ┌──────────┐ ┌───────────┐  │  │
│  │  │Task List│ │Task Form │ │Filter Bar │  │  │
│  │  └─────────┘ └──────────┘ └───────────┘  │  │
│  │         │            │           │        │  │
│  │         └────────────┴───────────┘        │  │
│  │                      │                    │  │
│  │            tRPC Client (类型安全)          │  │
│  └──────────────────────┼──────────────────-─┘  │
└─────────────────────────┼───────────────────────┘
                          │ HTTP
┌─────────────────────────┼───────────────────────┐
│                    Node.js Server                │
│  ┌──────────────────────┼───────────────────-─┐  │
│  │            tRPC Router                      │  │
│  │  ┌────────────┐ ┌──────────┐ ┌──────────┐  │  │
│  │  │task.create │ │task.list │ │task.done │  │  │
│  │  └─────┬──────┘ └────┬─────┘ └────┬─────┘  │  │
│  │        └──────────────┴────────────┘        │  │
│  │                     │                       │  │
│  │              Prisma / Drizzle               │  │
│  └─────────────────────┼──────────────────-────┘  │
│                         │                          │
│                  ┌──────┴──────┐                   │
│                  │  SQLite/    │                   │
│                  │  PostgreSQL │                   │
│                  └─────────────┘                   │
└────────────────────────────────────────────────────┘
```

**技术要求**：

- **Monorepo** 结构：`packages/server/` + `packages/web/` + `packages/shared/`（pnpm workspace 或 Turborepo）
- **Shared 包**：Zod schema + Prisma 生成的类型，前端后端各取所需
- **tRPC** 实现端到端类型安全：后端改一个字段，前端立刻编译报错
- **Prisma** 定义数据模型，自动生成类型迁移到 SQLite（开发）/ PostgreSQL（生产）
- **React** 前端：用 TanStack Query（React Query）管理服务端状态
- 表单用 React Hook Form + Zod Resolver：前后端同一套校验规则
- 中间件：CORS、请求日志、认证占位（为阶段四准备）
- **ESLint + Prettier** 在 monorepo 中统一配置

**自检清单**：

- [ ] 事件循环中，`setTimeout(fn, 0)` 和 `Promise.resolve().then(fn)` 哪个先执行？为什么？
- [ ] `for await` 和 `Promise.all` 的使用场景有什么区别？
- [ ] tRPC 的"类型安全"边界在哪里？请求到达后端后，运行时还能保证类型吗？
- [ ] Prisma 生成的类型和手写的 TypeScript 接口有什么本质区别？
- [ ] 为什么 JavaScript 不适合 CPU 密集型任务？Node.js 如何规避这个问题？


---

## 阶段四：生产级 TypeScript（Week 10-12）

> **核心命题**：把前三个阶段的能力整合为生产就绪的服务，建立从开发到部署的完整认知

### 阶段目标

- 掌握生产级 TypeScript 项目的构建、测试、部署全链路
- 集成认证、可观测性、性能优化
- 理解 TypeScript 的 bundle/compile/tree-shake 流程
- 交付一个容器化、可部署的全栈 TypeScript 应用

### 核心主题

1. **项目架构**
   - Monorepo 实战：Turborepo / Nx / pnpm workspaces
   - 包边界设计：`shared/`（类型+校验）→ `core/`（业务逻辑）→ `server/`（API）→ `web/`（UI）
   - 依赖方向：`web` → `core` → `shared`，`server` → `core` → `shared`，**禁止反向**
   - tRPC 的规模化使用：`appRouter`、middleware、context、procedure 复用
   - 配置管理：`dotenv` + `zod` 校验环境变量（启动时校验，不是运行时）

2. **测试**
   - Vitest：现代、快速的 TypeScript 测试框架（Jest 的替代品）
   - 单元测试：纯函数 + 类型守卫 + 工具函数
   - 集成测试：用 `testcontainers` 拉起真实数据库
   - API 测试：用 `supertest` + 测试数据库
   - 前端测试：React Testing Library + `userEvent`
   - E2E 测试：Playwright（比 Cypress 更推荐）
   - Mock 策略：`vi.mock` vs 依赖注入 vs MSW（Mock Service Worker）
   - 测试覆盖率：`vitest --coverage` + CI 门禁

3. **认证与安全**
   - JWT + refresh token 模式
   - 中间件验证：从 token 提取 user → 注入 `ctx.user`
   - `helmet`：基本的 HTTP 头安全
   - CORS 正确配置（不是 `Access-Control-Allow-Origin: *`）
   - `express-rate-limit`：API 限流
   - 输入校验：永远不信任客户端，运行时必须有 Zod
   - `npm audit` 和 `Dependabot`：依赖安全
   - 环境变量管理：敏感信息不进代码仓库

4. **可观测性**
   - 结构化日志：`pino`（比 `winston` 更快，比 `console.log` 强 100 倍）
   - 请求追踪：每个请求一个 `requestId`，贯穿日志
   - 错误监控：Sentry / 自建方案
   - 指标：`prom-client` 暴露 `/metrics`
   - 健康检查：`/health` (liveness) + `/ready` (readiness)
   - 分布式链路追踪：OpenTelemetry（不需要全链路，从入口 traceId 开始就可以）

5. **性能**
   - **bundle 体积**：Tree-shaking（ESM named exports）、Code splitting、Dynamic import
   - **首屏加载**：SSR/SSG（Next.js）、图片优化、字体加载策略
   - **服务端性能**：
     - 连接池：Prisma 的 connection limit
     - 数据库查询：用 Prisma 的 `select` 只取需要的字段
     - N+1 问题：`prisma.user.findMany({ include: { posts: true } })`
     - 缓存策略：内存缓存（lru-cache）、Redis
   - **Lighthouse 评分**：Performance、Accessibility、Best Practices、SEO
   - **bundle 分析**：`@next/bundle-analyzer` / `vite-bundle-visualizer`

6. **部署**
   - **Docker**：多阶段构建
     - Stage 1：安装依赖 + 编译（`tsc` / `next build`）
     - Stage 2：仅复制生产依赖 + 构建产物（`node_modules` 只包含 `dependencies` 不带 `devDependencies`）
   - **Node.js 生产最佳实践**：
     - `NODE_ENV=production`
     - `--enable-source-maps`（错误堆栈可读）
     - 优雅关闭：`process.on("SIGTERM", gracefulShutdown)`
   - **前端部署**：Vercel / Netlify / Cloudflare Pages / Docker
   - **后端部署**：Fly.io / Railway / Docker → K8s
   - **数据库**：PlanetScale / Supabase / Neon（Serverless Postgres）
   - **CI/CD**：GitHub Actions → lint → typecheck → test → build → deploy

7. **构建工具链理解**
   - **`tsc`（TypeScript 7.0+）**：类型检查 + 编译到 JS。编译器核心用 Go 重写，共享内存并行，`--checkers` 控制并行度
   - **TypeScript 6.x 兼容**：`@typescript/typescript6` 包提供 JS 版 tsc，用于需要旧编译器行为的场景
   - `tsup` / `unbuild`：TypeScript 库打包（底层用 esbuild，不类型检查）
   - `esbuild`：Go 写的极快 bundler/transpiler（不做类型检查！）
   - `swc`：Rust 写的 TS/JS 编译器（Next.js 用它替代 babel，也不做类型检查）
   - Vite：开发服务器 + 构建工具（esbuild 转译 + rollup 打包）
   - Turbopack：Next.js 13+ 的开发构建工具（Rust 实现）
   - **标准流程**：`tsc --noEmit`（类型检查，7.0 秒级完成） + esbuild/swc（转译，毫秒级） = 又快又安全
   - Source maps 管理：开发时生成，生产环境是否上传到监控平台

### 推荐资源

| 资源                                                                        | 用法                                          |
| --------------------------------------------------------------------------- | --------------------------------------------- |
| [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices) | 生产级 Node.js 的百科全书                     |
| [Bulletproof React](https://github.com/alan2207/bulletproof-react)          | 生产级 React 项目架构                         |
| [T3 Stack 文档](https://create.t3.gg/)                                      | Next.js + tRPC + Prisma + NextAuth 一体化方案 |
| [Testing JavaScript](https://testingjavascript.com/)（Kent C. Dodds）       | 从单元到 E2E 的完整测试思维                   |
| [Docker 官方 Node.js 指南](https://docs.docker.com/language/nodejs/)        | 多阶段构建最佳实践                            |
| [_Effective TypeScript_](https://effectivetypescript.com/) 第 6-8 章        | 类型声明、类型生成、迁移策略                  |
| [ts-reset](https://github.com/total-typescript/ts-reset)                    | 修复 TypeScript 标准库的类型缺陷              |
| [Playwright 官方文档](https://playwright.dev/)                              | E2E 测试的首选工具                            |

### 阶段项目：Taskly Production — 生产级全栈任务管理

**目标**：将阶段三的全栈应用重构为生产就绪的服务，可部署到公网。

```
最终架构（生产版）：

┌──────────────────────────────────────────────────────┐
│                    CI/CD Pipeline                     │
│  GitHub Actions: lint → typecheck → test → build     │
│                                     ↓                │
│                              Docker Build & Push      │
│                                     ↓                │
│                           Deploy to Fly.io / VPS     │
└──────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────┐
│                   Production App                      │
│                                                       │
│  ┌─────────────────┐       ┌──────────────────────┐ │
│  │   Next.js App    │       │   Nginx / Caddy      │ │
│  │   (SSR + API)    │──────▶│   (reverse proxy)    │ │
│  │                  │       │   + SSL (auto cert)  │ │
│  └────────┬─────────┘       └──────────────────────┘ │
│           │                                           │
│  ┌────────┴─────────┐                                │
│  │   PostgreSQL     │                                │
│  │   (Supabase/Neon)│                                │
│  └──────────────────┘                                │
│                                                       │
│  ┌──────────────────┐                                │
│  │   Redis (cache)  │    (optional)                  │
│  └──────────────────┘                                │
└──────────────────────────────────────────────────────┘
```

**技术要求**：

- **认证系统**：NextAuth.js (Auth.js) 实现邮箱密码 + OAuth（GitHub）登录
- **数据层**：Prisma + PostgreSQL（Supabase/Neon free tier）
- **中间件链**：auth → validation → rate-limiting → handler
- **日志**：pino 结构化日志，每个请求带 traceId
- **错误处理**：全局错误边界（前端）+ 统一错误响应格式（后端）
- **测试**：
  - 单元测试：业务逻辑函数（Vitest）
  - 集成测试：API endpoint + 真实测试数据库（Vitest + testcontainers）
  - E2E：核心用户流程（注册→登录→创建任务→完成→删除）（Playwright）
- **Docker**：多阶段构建，最终镜像 < 200MB
- **优雅关闭**：收到 SIGTERM → 停止接受新请求 → 等待活跃请求完成 → 断开 DB
- **CI**：PR → `tsc --noEmit` + `eslint` + `prettier --check` + `vitest` + Playwright
- **Makefile**：`dev`、`build`、`test`、`lint`、`db:migrate`、`db:seed`

**自检清单**：

- [ ] 你的 `tsconfig.json` 的 `strict` 选项全开了吗？`noUncheckedIndexedAccess` 开了吗？
- [ ] 优雅关闭：你的服务器在收到 SIGTERM 后还能处理完活跃请求吗？
- [ ] 前端 bundle 中，`node_modules` 代码占了多大比例？有没有 tree-shake 不了的依赖？
- [ ] 你的 Docker 镜像里是否包含了 `devDependencies` 和 `.ts` 源文件？
- [ ] 环境变量校验是在启动时做的，还是运行时才炸的？


---

## 长期进阶方向

完成四个阶段后，你已经是合格的生产级 TypeScript 开发者。以下是可选的精进方向：

| 方向                      | 内容                                                          | 起点                                                                                                          |
| ------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| **TypeScript 编译器源码** | 学习 7.0 的 Go 版编译器实现：checker、binder、type resolution | [TypeScript-Go 源码](https://github.com/microsoft/typescript-go)（Project Corsa）                             |
| **Bun / Deno 运行时**     | 探索 Node.js 的替代运行时，理解它们的差异化优势               | [Bun](https://bun.sh/) / [Deno](https://deno.com/)                                                            |
| **Rust 工具链**           | 理解 swc / turbopack / rolldown / oxc 的 Rust 实现            | [oxc-project](https://oxc-project.github.io/)                                                                 |
| **设计系统**              | 用 TypeScript 构建类型安全的组件库（Radix UI 级别的）         | [Radix UI](https://www.radix-ui.com/) / [Ark UI](https://ark-ui.com/)                                         |
| **GraphQL / tRPC 进阶**   | 深入理解类型安全 API 的设计哲学和实现细节                     | [tRPC GitHub](https://github.com/trpc/trpc) / [GraphQL Code Generator](https://the-guild.dev/graphql/codegen) |
| **WASM / 边缘计算**       | 用 AssemblyScript 或 Rust 编译到 WASM，在边缘运行时执行       | [Cloudflare Workers](https://workers.cloudflare.com/)                                                         |
| **源码阅读计划**          | 精读 Zod / tRPC / TanStack Query / Prisma 的源码              | 从 Zod 的 `z.object()` 实现开始                                                                               |
| **跨平台**                | React Native + TypeScript / Tauri（桌面端）/ Electron         | [Tauri](https://tauri.app/) / [Expo](https://expo.dev/)                                                       |

---

## 附录

### A. 常用命令速查

```bash
# 项目初始化
npm init -y                                  # 初始化 package.json
npm install -D typescript @types/node       # 安装 TypeScript
npx tsc --init                              # 生成 tsconfig.json
pnpm create vite                            # 用 Vite 创建前端项目
npx create-next-app@latest                  # 创建 Next.js 项目
npx create-t3-app@latest                    # 创建 T3 Stack 项目（Next.js + tRPC + Prisma + NextAuth）

# 类型检查与编译
npx tsc --noEmit                            # 仅类型检查（TS 7.0 后快 10 倍！）
npx tsc --noEmit --checkers 8               # TS 7.0+：8 线程并行类型检查
npx tsc --noEmit --builders 4               # TS 7.0+：4 线程并行构建
npx tsc --noEmit --watch                    # 类型检查的 watch 模式
npx tsc --project tsconfig.json             # 指定配置文件
npx tsc --version                           # 查看版本（7.0+ 即 Go 版）
npm install -D @typescript/typescript6      # 安装旧 JS 版 tsc（向后兼容用）

# 开发与运行
npx tsx src/server.ts                       # 直接运行 TypeScript 文件（开发用）
npx tsx --watch src/server.ts               # watch 模式（热重载）
npm run dev                                 # 通常是项目的开发命令

# 构建
npx tsc                                     # 编译到 JS
npm run build                               # 通常是项目构建命令
npx vite build                              # Vite 生产构建
npx next build                              # Next.js 生产构建

# 测试
npx vitest                                  # 运行 Vitest（watch 模式）
npx vitest run                              # 单次运行（CI 用）
npx vitest run --coverage                   # 测试覆盖率
npx playwright test                         # E2E 测试

# 代码质量
npx eslint .                                # 检查 ESLint 规则
npx eslint . --fix                          # 自动修复
npx prettier --check .                      # 检查格式
npx prettier --write .                      # 自动格式化

# 依赖管理
npm outdated                                # 查看过时依赖
npx npm-check-updates                       # 交互式更新依赖
npm audit                                   # 安全检查
pnpm why <package>                          # 为什么安装了这个包？
npx depcheck                                # 查找未使用的依赖

# Bundle 分析
ANALYZE=true npm run build                  # Next.js bundle 分析
npx vite-bundle-visualizer                  # Vite bundle 分析
npx source-map-explorer dist/**/*.js        # 分析任意 bundle
```

### B. TypeScript 工具链全景

```
tsconfig.json                     # TypeScript 项目配置
├── compilerOptions
│   ├── target                    # ES2015 ~ ESNext
│   ├── module                    # ESNext / NodeNext / Preserve
│   ├── moduleResolution          # bundler / node / node16
│   ├── strict                    # 严格模式总开关
│   │   ├── strictNullChecks      # null/undefined 类型检查
│   │   ├── noImplicitAny         # 禁止隐式 any
│   │   ├── strictFunctionTypes   # 严格函数类型检查
│   │   └── ...(更多子选项)
│   ├── paths                     # 路径别名
│   ├── outDir                    # 编译输出目录
│   ├── rootDir                   # 源码根目录
│   ├── declaration               # 生成 .d.ts 类型声明
│   ├── declarationMap            # 声明文件的 source map
│   ├── sourceMap                 # 生成 source map
│   ├── noUncheckedIndexedAccess  # 索引访问加 undefined
│   └── exactOptionalPropertyTypes # 精确可选属性
├── include                       # 包含的文件 glob
├── exclude                       # 排除的文件 glob
└── references                    # 项目引用（monorepo）

构建工具生态：
tsc (TS 7.0+: Go 实现，~10x 性能)  # 官方编译器（类型检查 + 编译）
│                                   # 新参数: --checkers, --builders
├── tsup / unbuild                  # 基于 esbuild 的库打包
├── vite                            # 开发服务器 + 构建（esbuild + rollup）
├── webpack                         # 老牌打包器（CRA 默认）
├── turbopack                       # Next.js 13+ 的 Rust 构建（替代 webpack）
├── swc                             # Rust TS/JS 编译器（极快，不做类型检查）
├── esbuild                         # Go 写的极速 bundler（不做类型检查）
└── @typescript/typescript6         # 向后兼容包（旧 JS 版 tsc）

npm / yarn / pnpm     # 包管理器
├── package.json      # 项目元数据 + 依赖声明 + scripts
├── node_modules/     # 依赖安装目录
├── package-lock.json # 依赖锁文件
└── pnpm-workspace.yaml # Monorepo 配置
```

### C. 必备工具清单

```bash
# 全局安装（开发环境必备）
npm install -g pnpm                              # 更快的包管理器（推荐替代 npm）
npm install -g typescript                        # tsc 命令

# 项目 devDependencies（按需安装）
npm install -D typescript @types/node           # TypeScript + Node 类型
npm install -D eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin
npm install -D prettier eslint-config-prettier
npm install -D vitest                           # 测试框架
npm install -D zod                              # 运行时校验
npm install -D tsup                             # 库打包
npm install -D lint-staged simple-git-hooks     # Pre-commit hooks
npm install -D depcheck                         # 查找未使用的依赖
npm install -D knip                             # 更强大的 dead code 检测

# VS Code 必备扩展
# - TypeScript (内置)
# - ESLint
# - Prettier
# - Error Lens (内联显示错误)
# - Pretty TypeScript Errors
# - Console Ninja (inline console.log)
```

### D. 社区与持续学习

| 渠道                                                                                  | 说明                                |
| ------------------------------------------------------------------------------------- | ----------------------------------- |
| [TypeScript Discord](https://discord.gg/typescript)                                   | 官方 Discord 社区                   |
| [r/typescript](https://reddit.com/r/typescript)                                       | Reddit TypeScript 社区              |
| [TypeScript Weekly](https://typescript-weekly.com/)                                   | 每周邮件精选                        |
| [Total TypeScript](https://www.totaltypescript.com/)（Matt Pocock）                   | 最好的 TypeScript 教育资源          |
| [Syntax.fm Podcast](https://syntax.fm/)                                               | Wes Bos & Scott Tolinski 的全栈播客 |
| [JavaScript Weekly](https://javascriptweekly.com/)                                    | JS/TS 生态周报                      |
| [前端技术月刊](https://github.com/ljianshu/Blog/issues)                               | 中文前端精华文章聚合                |
| [React Conf](https://www.youtube.com/c/ReactConf) / [ViteConf](https://viteconf.org/) | 年度会议视频                        |

---

> **最后的建议**：12 周后，不要停在这里。TypeScript 生态变化极快——React Server Components、Bun、Bun.sh、tRPC v11、TanStack Start 每个月都有新东西。但这不代表你要追每一个新趋势。**真正的能力是：用类型系统对业务建模，而不是用类型系统炫技。** 找一个问题去解决——工作中的内部工具、开源项目的 Good First Issue、或者一个困扰你很久的个人痛点——用 TypeScript 去实现它。语言和框架在变，但类型思维和工程直觉会跟随你一辈子。
