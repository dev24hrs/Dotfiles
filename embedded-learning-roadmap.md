# 嵌入式开发学习路线图：从软件工程师到嵌入式工程师

> **目标读者**：有 Java / 后端工程经验的软件开发者  
> **学习周期**：16-20 周（每周 10-15 小时），分三阶段  
> **最终产出**：能独立设计并实现一个完整的嵌入式系统（MCU + 外设 + RTOS / Embedded Linux）

---

## 前言：嵌入式开发是什么

嵌入式开发不是"一种技术"，而是一个**技术栈光谱**——从裸机寄存器操作到运行 Linux 的 Cortex-A，差异巨大：

```
裸机 (Bare Metal)          RTOS               Embedded Linux
═══════════════          ══════              ═══════════════
无操作系统                 实时内核             完整 Linux 内核
MCU (STM32/AVR)          MCU/MPU             MPU (Cortex-A)
手动管理一切              任务调度+IPC          多进程+文件系统
KB 级 RAM                MB 级 RAM            GB 级 RAM
C + 汇编                 C + C++             C/C++/Rust/Go/Python
```

### 为什么嵌入式值得学

| 维度 | 纯软件开发 | 嵌入式开发 |
|------|-----------|-----------|
| **反馈感** | 看到 UI 变化 | 看到物理世界响应（LED 闪烁、电机转动） |
| **资源意识** | GB 级内存，不够就加 | 64KB-1MB RAM，用完就是硬故障 |
| **调试方式** | print/log/断点 | 逻辑分析仪、示波器、JTAG 硬件断点 |
| **代码寿命** | 可能下周重构 | 可能运行 10 年不重启 |
| **错误代价** | 500 页面 | 物理损坏、安全事故 |
| **知识半衰期** | 框架 2-3 年换代 | C 语言用了 50 年，ARM 架构用了 30 年 |

### 从 Java 到嵌入式的思维转变

| Java 思维 | 嵌入式现实 |
|-----------|-----------|
| "内存不够？加 JVM heap" | 你有 64KB RAM，用完就没了 |
| "出错了？抛异常看栈" | 出错了？芯片可能 HardFault，没有栈给你看 |
| "这个库怎么用？看 javadoc" | 看芯片数据手册第 347 页的寄存器描述 |
| "字符串拼接慢？换 StringBuilder" | `printf` 本身可能吃掉一半 Flash |
| "重启就好了" | 你的代码在产品里跑 10 年不能重启 |
| "null pointer → NPE" | 悬空指针 → 读到随机值或硬件异常，极难复现 |
| "GC 帮我管理内存" | 你 malloc 的每一块，你都得 free。忘了就泄漏，double free 就崩 |
| "import 就能用" | 你需要读懂原理图才知道 GPIO 连到哪了 |

---

## 必备硬件采购清单

在开始学习之前，你需要一些硬件。**不需要一次性买齐**，按阶段采购：

### 阶段一基础装备（总预算 ¥150-300）

| 物品 | 推荐型号 | 价格 | 用途 |
|------|---------|------|------|
| **开发板** | STM32 Nucleo-F446RE | ¥80-100 | ARM Cortex-M4，社区资源最多，Arduino 兼容排针 |
| **逻辑分析仪** | 24MHz 8CH (Saleae 克隆) | ¥30-50 | 调试 UART/I2C/SPI，嵌入式开发的"眼睛" |
| **杜邦线** | 公母各一盒 | ¥10 | 连接外设 |
| **面包板** | 830 孔 | ¥15 | 免焊原型验证 |

### 阶段二扩展（总预算 ¥100-200）

| 物品 | 推荐型号 | 价格 | 用途 |
|------|---------|------|------|
| **传感器套装** | DHT22 + BMP280 + MPU6050 + OLED (SSD1306) | ¥50-80 | I2C/SPI 驱动实战 |
| **电机驱动** | L298N + 小型直流电机 | ¥20 | PWM 控制实战 |
| **USB-TTL 模块** | CP2102 或 CH340 | ¥10 | 串口调试 |

### 阶段三可选（Embedded Linux 方向）

| 物品 | 推荐型号 | 价格 | 用途 |
|------|---------|------|------|
| **Linux 开发板** | 树莓派 4B/5 或 STM32MP157F-DK2 | ¥300-800 | Embedded Linux 实战 |
| **调试器升级** | J-Link EDU Mini | ¥200 | 比 ST-Link 快，支持更多芯片 |

---

## 阶段一：裸机入门（Week 1-6）

> **核心命题**：理解 MCU 怎么工作，从点亮一个 LED 到写出完整的外设驱动

### 阶段目标

- 搭建嵌入式开发环境（交叉编译工具链、烧录、调试）
- 掌握 C 语言在嵌入式场景的核心用法（指针、位操作、volatile、中断）
- 能看懂原理图和数据手册，独立配置外设寄存器
- 写出第一个完整的传感器采集 + 显示项目

### 核心主题

#### 1. C 语言嵌入式专项（Week 1-2）

从 Java 背景出发，重点补 C 语言中嵌入式特有的部分：

| 主题 | 说明 | 为什么 Java 开发者需要特别关注 |
|------|------|-------------------------------|
| **指针与内存** | 指针算术、函数指针、`void*`、`const` 指针 | Java 没有指针，这是最大概念转变 |
| **位操作** | `\|` `&` `^` `~` `<<` `>>`，bit-field struct | 寄存器操作就是位操作 |
| **`volatile`** | 告诉编译器"每次访问都要从内存读，不能优化" | Java 的 volatile 是内存可见性，C 的是禁止优化，完全不同 |
| **`static` / `extern`** | 文件作用域 vs 全局作用域 | Java 没有文件作用域概念 |
| **函数指针** | 回调、中断向量表、状态机 | 类似 Java 的 Lambda/方法引用，但更底层 |
| **结构体内存布局** | 对齐（alignment）、填充（padding）、`__attribute__((packed))` | 映射硬件寄存器必须精确控制布局 |
| **预处理器** | `#define`、`#ifdef`、`#include` guard、宏函数 | Java 没有预处理器 |

```c
// 嵌入式 C 的日常：直接操作寄存器地址
// Java 开发者注意：这不是"魔法数字"，这是芯片数据手册第 6.3.2 节定义的地址

#define GPIOA_BASE   0x40020000UL   // GPIOA 基地址（查数据手册 Memory Map）
#define GPIOA_MODER  (*(volatile uint32_t *)(GPIOA_BASE + 0x00))  // 模式寄存器
#define GPIOA_ODR    (*(volatile uint32_t *)(GPIOA_BASE + 0x14))  // 输出数据寄存器

// 配置 PA5 为输出模式（两个 bit 控制一个引脚）
GPIOA_MODER &= ~(0x3 << 10);   // 清除 PA5 的模式位（bit 10-11）
GPIOA_MODER |=  (0x1 << 10);   // 设置为通用输出模式

// 点亮 PA5 上的 LED
GPIOA_ODR |= (1 << 5);         // 设置 PA5 输出高电平

// 这些代码在 Java 看来毫无上下文 —— 但在嵌入式里，
// 数据手册就是你所有上下文
```

#### 2. ARM Cortex-M 架构基础（Week 2-3）

| 主题 | 必须理解到什么程度 |
|------|-------------------|
| **存储器映射** | Flash 在哪、RAM 在哪、外设寄存器在哪——芯片数据手册的 Memory Map 章节 |
| **寄存器组** | R0-R12（通用）、R13/SP（栈指针）、R14/LR（链接寄存器）、R15/PC（程序计数器） |
| **中断系统** | NVIC（嵌套向量中断控制器）、优先级、中断向量表 |
| **时钟树** | HSI/HSE/PLL，为什么配置时钟是第一步 |
| **启动流程** | Reset Handler → 初始化 `.data` 段 → 清零 `.bss` → 调用 `main()` |
| **栈与堆** | 链接器脚本里怎么定义栈大小、栈溢出了会怎样 |

```arm
; 启动文件的关键片段（startup_stm32f446xx.s）
; 理解这段汇编就够了，不需要手写

g_pfnVectors:              ; 中断向量表 —— 芯片上电后硬件先读这里
  .word  _estack           ; 0x0000: 初始栈指针（MSP）
  .word  Reset_Handler     ; 0x0004: 复位后第一条指令的地址
  .word  NMI_Handler       ; 0x0008: 不可屏蔽中断
  .word  HardFault_Handler ; 0x000C: 硬错误 —— 你很快会在这见到它
  ; ... 更多中断向量

Reset_Handler:
  ldr   sp, =_estack       ; 设置栈指针
  bl    SystemInit         ; 配置时钟
  bl    __libc_init_array  ; 初始化 C 运行时
  bl    main               ; 终于进入你的 main() 函数
  bx    lr                 ; main 返回后死循环
```

#### 3. 外设驱动开发（Week 3-5）

每个外设按这个顺序学：**看原理图找到引脚 → 查数据手册了解寄存器 → 配置时钟 → 配置外设 → 读写数据**

| 外设 | 学习重点 | 实践 |
|------|---------|------|
| **GPIO** | 输入/输出/复用/模拟 四种模式、上下拉、开漏 vs 推挽 | 按键控制 LED |
| **EXTI（外部中断）** | 中断触发边沿、去抖动、中断优先级 | 按键中断替代轮询 |
| **Timer** | 预分频器、自动重装载、PWM 输出、输入捕获 | 呼吸灯、测量脉宽 |
| **UART** | 波特率、起始位/停止位、FIFO、DMA 传输 | 串口打印 Hello World |
| **I2C** | 起始/停止条件、ACK/NACK、7 位地址、多主仲裁 | 读取温湿度传感器 |
| **SPI** | CPOL/CPHA 四种模式、全双工、片选信号 | 驱动 OLED 显示屏 |
| **ADC** | 采样率、分辨率、参考电压、DMA 连续转换 | 读取电位器/光敏电阻 |

```c
// UART 发送一个字符（手写寄存器版本 vs HAL 版本对比）

// == 方式一：直接操作寄存器（理解原理用，生产代码一般不用）==
void uart_send_byte_reg(uint8_t data) {
    // 等待发送数据寄存器为空（检查 USART_SR 的 TXE 位）
    while (!(USART2->SR & USART_SR_TXE));
    USART2->DR = data;  // 写入数据寄存器，硬件自动发送
}

// == 方式二：STM32 HAL 库（实际项目用）==
void uart_send_byte_hal(uint8_t data) {
    HAL_UART_Transmit(&huart2, &data, 1, HAL_MAX_DELAY);
}
// 看似简单？HAL_UART_Transmit 内部同样在轮询 TXE 标志位。
// 理解寄存器版本，你才知道 HAL 封装了什么、有什么局限。
```

#### 4. 调试方法论（贯穿全程）

| 调试手段 | 适用场景 | 工具 |
|---------|---------|------|
| **串口打印** | 变量值、程序流程 | USB-TTL + 终端 |
| **硬件断点** | 停在特定位置，查看寄存器和内存 | STM32CubeIDE 调试器或 VSCode + Cortex-Debug |
| **逻辑分析仪** | I2C/SPI/UART 通信是否正常、时序是否正确 | PulseView (开源) |
| **HardFault 分析** | 程序跑飞、非法访问 | 查看 SCB 寄存器（CFSR/HFSR/MMFAR/BFAR）定位根因 |

### 推荐资源

| 资源 | 用法 |
|------|------|
| [*Making Embedded Systems*](https://www.oreilly.com/library/view/making-embedded-systems/9781449308889/) (Elecia White) | **第一本要读的书**。讲的是思维方式——状态机、功耗管理、调试哲学，不绑定具体芯片 |
| [*Mastering STM32*](https://leanpub.com/mastering-stm32-2nd) (Carmine Noviello) | STM32 的百科全书，1000+ 页。别试图通读，当作参考书用 |
| [FastBit Embedded Brain Academy](https://www.udemy.com/user/kiran-nayak-2/) (Udemy) | **最好的 STM32 视频课程**。Kiran 会带你从寄存器层面理解每个外设 |
| [STM32F4 Reference Manual](https://www.st.com/resource/en/reference_manual/rm0390-stm32f446xx-advanced-armbased-32bit-mcus-stmicroelectronics.pdf) | 这是你的"API 文档"——不是可选读物，是必备参考 |
| [Embedded Artistry](https://embeddedartistry.com/) | 嵌入式 C/C++ 最佳实践、构建系统设计 |
| [Interrupt Blog (Memfault)](https://interrupt.memfault.com/blog/) | 工业级嵌入式软件工程，coredump、OTA、文件系统 |

### 阶段项目一：温湿度监控器（Week 4-6）

**目标**：从零构建一个完整的数据采集与显示系统。

```
系统框图：

┌─────────────┐   I2C    ┌──────────┐
│  DHT22/     │──────────▶│          │
│  AHT20      │           │          │   I2C    ┌──────────┐
│  温湿度传感器 │           │  STM32   │──────────▶│ SSD1306   │
└─────────────┘           │  F446RE  │          │ OLED 显示  │
                          │          │          └──────────┘
┌─────────────┐   GPIO   │          │   UART   ┌──────────┐
│  按键        │──────────▶│          │──────────▶│ USB-TTL   │
│ (模式切换)   │           │          │          │ 串口打印   │
└─────────────┘           └──────────┘          └──────────┘
```

**功能要求**：

1. **传感器采集**：通过 I2C 读取 DHT22 / AHT20 的温湿度数据
2. **OLED 显示**：用 I2C 驱动 SSD1306 OLED 屏，显示温度、湿度和一个简单的状态图标
3. **按键交互**：短按切换显示模式（当前值 / 历史最高/最低），长按清零统计
4. **串口输出**：每秒通过 UART 打印格式化的温湿度数据
5. **异常检测**：温度超过阈值时，LED 闪烁告警

**技术约束**：

- 用 STM32CubeIDE 生成初始化代码，理解 HAL 做了什么
- 每个外设驱动至少读一遍对应的 HAL 源码，知道寄存器层面发生了什么
- 使用定时器中断（不是 `HAL_Delay`）实现周期性采集和 LED 闪烁
- 状态机管理按键逻辑（而非在中断里写业务逻辑）
- 合理组织代码：`drivers/` + `app/` + `utils/`

**扩展到阶段二的思路**：将来用 FreeRTOS 把采集、显示、通信拆成三个独立任务。

### 检验标准

- [ ] 能否对着 STM32F4 数据手册的 Memory Map，说出 Flash、SRAM、外设总线的地址范围？
- [ ] `volatile` 在嵌入式 C 中的作用是什么？去掉它优化全开会有什么后果？
- [ ] I2C 的起始条件和停止条件分别是什么信号？
- [ ] 你的 ADC 读数为什么会跳？怎么处理？（硬件滤波 vs 软件滤波）
- [ ] HardFault 发生后，你要看哪几个寄存器来定位原因？
- [ ] STM32 上电后，`main()` 被调用之前发生了什么？
- [ ] 中断服务函数（ISR）为什么应该尽量短？在 ISR 里阻塞等 UART 发送完成会导致什么？

---

## 阶段二：RTOS 与实时系统（Week 7-12）

> **核心命题**：当裸机逻辑复杂到一定程度时，引入实时操作系统来管理并发

### 阶段目标

- 理解实时操作系统（RTOS）的核心机制与调度原理
- 将裸机项目用 FreeRTOS 重构，体验"有没有 OS"的设计差异
- 掌握任务间通信的四种方式及其适用场景
- 能分析并解决优先级反转、死锁等实时系统经典问题

### 核心主题

#### 1. RTOS 内核机制（Week 7-8）

| 主题 | 必须掌握什么 |
|------|-------------|
| **任务调度** | 抢占式调度 vs 协作式调度、优先级、时间片、就绪表 |
| **任务状态** | Running / Ready / Blocked / Suspended —— 和 Linux 进程状态类似但有细微差别 |
| **上下文切换** | 保存/恢复寄存器、PSP/MSP 双栈（Cortex-M 特有）、PendSV 异常 |
| **Tick 中断** | SysTick 定时器驱动调度心跳，`configTICK_RATE_HZ` |
| **空闲任务** | Idle Task Hook：低功耗入口、统计 CPU 利用率 |

```c
// FreeRTOS 创建任务 —— 比 Java Thread 更"可见"的并发
// Java: new Thread(() -> { ... }).start();
// FreeRTOS:

void SensorTask(void *pvParameters) {
    // 每个任务都是无限循环
    for (;;) {
        float temp = read_temperature();
        // 发送到队列（不是直接写全局变量）
        xQueueSend(sensorQueue, &temp, portMAX_DELAY);
        vTaskDelay(pdMS_TO_TICKS(1000));  // 阻塞 1 秒，让出 CPU
    }
}

// 创建任务时你需要指定：栈大小、优先级、入口函数
// 不像 Java 的线程默认 1MB 栈——这里每个任务可能只有 128 字节栈
xTaskCreate(
    SensorTask,          // 入口函数
    "Sensor",            // 任务名（调试用）
    configMINIMAL_STACK_SIZE * 2,  // 栈大小（字，不是字节）
    NULL,                // 参数
    tskIDLE_PRIORITY + 2, // 优先级
    NULL                 // 任务句柄（不需要时传 NULL）
);
```

#### 2. 任务间通信（Week 9-10）

| 机制 | 特性 | 适用场景 |
|------|------|---------|
| **Queue（队列）** | FIFO、拷贝传递（非指针）、可阻塞等待 | 数据流：传感器→处理→显示 |
| **Semaphore（信号量）** | 计数型、二值型、用于同步而非数据传输 | 中断通知任务、"资源可用"信号 |
| **Mutex（互斥锁）** | 带优先级继承的二值信号量 | 保护共享资源，解决优先级反转 |
| **Task Notification** | 最快的通知机制，无需预先创建队列 | 轻量级事件通知 |
| **Event Groups** | 多事件位组合，"等待任一/全部事件发生" | 等待多个传感器都就绪 |
| **Stream/Message Buffer** | 任意长度字节流 | 日志缓冲、命令解析 |

**优先级反转与优先级继承**：

```
场景：高优先级任务 H、中优先级 M、低优先级 L

没有优先级继承：
  L 持有锁 → H 请求锁（阻塞）→ M 抢占 L（L 无法释放锁）
  → H 被 M 无限阻塞（虽然 H 优先级最高！）
  → 这就是 1997 年火星探路者死机的原因。

有优先级继承（FreeRTOS Mutex 默认开启）：
  L 持有锁 → H 请求锁 → L 临时继承 H 的优先级
  → M 无法抢占 L → L 快速完成释放锁 → H 获得锁运行
```

#### 3. 中断管理（Week 11）

| 概念 | 说明 |
|------|------|
| **ISR 设计原则** | 越短越好——只做必要的事（清中断标志、拷贝关键数据），其余交给任务 |
| **Deferred Interrupt Processing** | ISR 设置标志/发信号量 → 一个高优先级任务真正处理 |
| **FromISR API** | 所有 FreeRTOS API 都有 ISR 版本：`xQueueSendFromISR()` 等 |
| **临界区** | `taskENTER_CRITICAL()` / `taskEXIT_CRITICAL()` —— 关闭中断，越短越好 |
| **中断优先级** | `configMAX_SYSCALL_INTERRUPT_PRIORITY` —— 高于此值的 ISR 不能调 FreeRTOS API |

#### 4. 内存管理（Week 12）

| 主题 | 说明 |
|------|------|
| **静态 vs 动态分配** | 嵌入式首选静态（编译时确定大小），动态分配需要评估碎片风险 |
| **FreeRTOS 内存方案** | heap_1（最简单）→ heap_4（最佳通用）→ heap_5（多块内存区域） |
| **栈溢出检测** | `configCHECK_FOR_STACK_OVERFLOW` + `uxTaskGetStackHighWaterMark()` |
| **为什么禁 `malloc`** | 碎片化、执行时间不确定、分配失败处理 |

### 推荐资源

| 资源 | 用法 |
|------|------|
| [*Mastering the FreeRTOS Kernel*](https://www.freertos.org/Documentation/RTOS_book.html) (官方免费 PDF) | **精读**。FreeRTOS 作者自己写的，源码级讲解 |
| [FreeRTOS API Reference](https://www.freertos.org/a00106.html) | 日常 API 查询 |
| [FreeRTOS 交互式教程](https://www.freertos.org/FreeRTOS-simulator-for-Windows.html) | Windows 模拟器，无需硬件即可实验 |
| [*Real-Time C++*](https://link.springer.com/book/10.1007/978-3-662-62912-7) (Christopher Kormanyos) | 如果将来要在嵌入式用 C++ |

### 阶段项目二：多任务数据采集系统

**目标**：用 FreeRTOS 重写阶段一的项目，并扩展功能。

```
任务划分：

┌─────────────┐   Queue    ┌──────────────┐   Queue   ┌──────────────┐
│ SensorTask  │───────────▶│ ProcessTask  │──────────▶│ DisplayTask  │
│ 优先级: 3    │  原始数据   │ 优先级: 2     │  处理后   │ 优先级: 1     │
│ 周期: 100ms │            │ 滤波+单位转换 │  数据     │ 周期: 200ms  │
└──────┬──────┘            └──────────────┘           └──────────────┘
       │ Semaphore (ISR → Task)
┌──────┴──────┐            ┌──────────────┐
│ 按键 ISR    │    Queue   │ CommandTask  │
│ EXTI 中断   │───────────▶│ 优先级: 4     │
└─────────────┘   命令码    │ CLI 命令解析   │
                           └──────┬───────┘
                                  │ 控制其他任务
                           ┌──────┴───────┐
                           │ UART (DMA)   │
                           └──────────────┘
```

**功能要求**：

1. **SensorTask**（优先级 3）：100ms 采集一次温湿度 + ADC 光照值，通过 Queue 发送
2. **ProcessTask**（优先级 2）：接收原始数据，做滑动平均滤波、单位转换，发送给 DisplayTask
3. **DisplayTask**（优先级 1）：200ms 刷新一次 OLED，展示数据 + 趋势箭头
4. **CommandTask**（优先级 4）：UART 接收命令（用户通过串口发送 `mode:minmax`、`rate:500`），修改系统参数
5. **按键 ISR**：通过 Semaphore 通知 ProcessTask 切换显示模式（不要按键消抖放在 ISR 里！）
6. **Watchdog Task**：最低优先级，喂狗的同时检测所有任务是否还在运行

**技术约束**：

- 每个任务用 `uxTaskGetStackHighWaterMark()` 监控栈使用量，调整栈大小到合理值
- 用 Mutex（非 Semaphore）保护 OLED 等不可重入资源
- ProcessTask 和 CommandTask 不能直接修改 SensorTask 的状态——通过 Queue 传递 ControlMsg
- 记录一次优先级反转场景（故意构造），然后用 Mutex 的优先级继承解决

### 检验标准

- [ ] 抢占式调度和协作式调度的核心区别是什么？嵌入式为什么用抢占式？
- [ ] 优先级反转是怎么发生的？优先级继承如何解决它？
- [ ] Queue 传递的是数据副本还是指针？为什么这样设计？
- [ ] ISR 里为什么不能用 `xQueueSend` 而必须用 `xQueueSendFromISR`？
- [ ] 你的 DisplayTask 栈用了多少字节？如果只剩 20 字节会发生什么？
- [ ] 裸机和 RTOS 的核心设计差异——什么时候该上 RTOS，什么时候不该？
- [ ] FreeRTOS 的 Tick 中断频率应该设多高？太高/太低各有什么问题？
- [ ] 如果用 `taskENTER_CRITICAL()` 保护一大段代码会怎样？

---

## 阶段三：分支深入（Week 13-20+）

完成前两个阶段后，你有了选择权。三个主流方向：

---

### 方向 A：嵌入式驱动深耕

> 目标：进入芯片原厂驱动团队，或成为底层驱动专家

| 技能 | 学习内容 |
|------|---------|
| **手写外设驱动** | 脱离 HAL，直接操作寄存器写 I2C/SPI/UART 驱动。理解中断+DMA 的最佳实践 |
| **Bootloader** | 实现自定义 Bootloader：Flash 分区、固件校验（CRC/SHA）、安全启动 |
| **低功耗设计** | STM32 的 Sleep/Stop/Standby 模式、Tickless Idle、功耗测量 |
| **实时信号处理** | DSP 库（CMSIS-DSP）、ADC + DMA 双缓冲 + FFT |
| **安全** | TrustZone (Cortex-M33+)、Secure Boot、固件加密 |

**资源**：STM32 应用笔记（AN2606 Bootloader，AN4899 低功耗），ARM Cortex-M 技术参考手册

---

### 方向 B：Embedded Linux

> 目标：成为 IoT 网关、工业平板、BSP 工程师

| 技能 | 学习内容 |
|------|---------|
| **构建系统** | Buildroot（入门简单）→ Yocto（工业标准） |
| **U-Boot** | 引导流程、设备树传递、启动脚本 |
| **内核模块** | 字符设备驱动、Platform Driver、设备树绑定 |
| **用户态驱动** | GPIO/sysfs、SPIdev、I2Cdev、UIO |
| **文件系统** | SquashFS + OverlayFS（只读根文件系统 + 可写层）|

**资源**：*Linux Device Drivers* 第3版（LDD3），*Mastering Embedded Linux Programming* (Chris Simmonds)，Bootlin 的免费培训材料

**核心项目**：用 Buildroot 为树莓派构建一个只读根文件系统 + 写一个 I2C 字符设备驱动

---

### 方向 C：Rust 嵌入式

> 目标：走在嵌入式语言演进的前沿

| 技能 | 学习内容 |
|------|---------|
| **embassy-rs** | Rust 异步嵌入式框架，用 `async/await` 写裸机 |
| **probe-rs** | Rust 原生的调试和烧录工具，替代 OpenOCD |
| **embedded-hal** | Rust trait 定义的标准外设抽象 |
| **RTIC** | 基于中断的实时并发框架 |

**资源**：[The Embedded Rust Book](https://docs.rust-embedded.org/book/)，[embassy 官方文档](https://embassy.dev/)

**核心项目**：用 embassy-rs 重写阶段一的温湿度监控器，对比 C 版本的安全性差异

---

## 嵌入式学习特有的方法与习惯

### 1. 学会读数据手册

数据手册是你最重要的教材。以 STM32F446RE Reference Manual 为例：

```
你需要的信息              手册的对应章节
─────────────────────    ─────────────────
这个引脚能做什么？           3. Pinouts and pin description
Flash/RAM/SRAM 在哪？      2. Memory and bus architecture
时钟怎么配？               6. Reset and clock control (RCC)
GPIO 有哪些模式？           8. General-purpose I/Os (GPIO)
UART 波特率怎么算？         27. Universal synchronous asynchronous receiver
I2C 时序参数？             28. Inter-integrated circuit (I2C) interface
中断优先级怎么设？          12. Interrupts and events
寄存器具体什么位？          对应章节末尾的 Register Map
```

**阅读技巧**：先看功能框图（Block Diagram）→ 再看寄存器描述 → 最后看时序图。不要从头读到尾。

### 2. 建立嵌入式调试心智模型

```
纯软件调试： printf → log → 断点 → 堆栈
嵌入式调试： 硬件断点(JTAG) → 逻辑分析仪 → 串口 → LED 闪烁
             ↑              ↑             ↑        ↑
            寄存器级        时序级        数据级    最粗糙但可靠
```

### 3. 嵌入式开发的"黄金法则"

- **不要相信 HAL**：永远去读 HAL 源码，知道它封装了什么、漏了什么
- **先看波形再写代码**：调试通信问题时，逻辑分析仪比 debugger 更快定位
- **栈比堆更重要**：嵌入式堆用多了会碎片化，但栈溢出是即死——永远监控栈
- **在 ISR 里做最少的事**：清标志、记数据、发信号——然后立刻退出
- **看门狗不是可选项**：没有看门狗的系统不可靠

---

## 语言与岗位对照

| 角色 | 主要语言 | 薪资参考（2025-2026 中国） | 入行难度 |
|------|---------|--------------------------|---------|
| MCU 裸机开发 | C | 15-30K | ⭐⭐⭐⭐ |
| RTOS 应用开发 | C + C++ | 18-35K | ⭐⭐⭐ |
| 嵌入式 Linux BSP | C | 20-40K | ⭐⭐⭐⭐⭐ |
| 嵌入式 Linux 应用 | C++ / Rust / Go | 20-40K | ⭐⭐⭐ |
| IoT 平台开发 | Go / Python / Java | 20-45K | ⭐⭐（对你最容易）|
| 芯片原厂驱动 | C | 25-50K | ⭐⭐⭐⭐⭐ |

---

## 附录

### A. 常用工具速查

```bash
# == 编译工具链 ==
arm-none-eabi-gcc --version        # ARM 裸机交叉编译器
arm-none-eabi-objdump -d fw.elf    # 反汇编查看生成的机器码
arm-none-eabi-size fw.elf          # 查看 Flash/RAM 用量
arm-none-eabi-nm fw.elf            # 查看符号表（函数/变量地址）

# == 调试 ==
openocd -f board/st_nucleo_f4.cfg  # 启动 OpenOCD 调试服务器
arm-none-eabi-gdb fw.elf           # 连接 GDB
  (gdb) target remote :3333        # 连接 OpenOCD
  (gdb) monitor reset halt         # 复位并暂停
  (gdb) info registers             # 查看所有 CPU 寄存器
  (gdb) x/10x 0x20000000           # 查看内存（RAM 起始地址）

# == 逻辑分析仪 (PulseView / sigrok) ==
# 抓取 I2C 波形 → 内置协议解码器 → 直接看到寄存器地址和数据
```

### B. 核心术语速查

| 缩写 | 全称 | 含义 |
|------|------|------|
| **MCU** | Microcontroller Unit | 单片机，CPU+RAM+Flash+外设在一颗芯片 |
| **MPU** | Microprocessor Unit | 微处理器，只有 CPU，需要外挂 RAM/Flash |
| **SoC** | System on Chip | 片上系统，MCU/MPU + GPU + NPU + ... |
| **HAL** | Hardware Abstraction Layer | 硬件抽象层——厂商写的库 |
| **BSP** | Board Support Package | 板级支持包——为特定板卡定制的驱动和配置 |
| **ISR** | Interrupt Service Routine | 中断服务函数 |
| **DMA** | Direct Memory Access | 直接内存访问——数据传输不经过 CPU |
| **NVIC** | Nested Vectored Interrupt Controller | 嵌套向量中断控制器 (ARM) |
| **JTAG/SWD** | Joint Test Action Group / Serial Wire Debug | 硬件调试接口 |
| **RTOS** | Real-Time Operating System | 实时操作系统 |
| **Device Tree** | Device Tree | 描述硬件拓扑的数据结构 (Linux) |
| **OTP** | One-Time Programmable | 一次性可编程——烧写后不可更改 |

### C. 推荐社区与持续学习

| 渠道 | 说明 |
|------|------|
| [r/embedded](https://reddit.com/r/embedded) | 最活跃的嵌入式英文社区 |
| [Embedded.fm](https://embedded.fm/) | Elecia White 的播客，每周更新，行业视野极佳 |
| [Memfault Interrupt](https://interrupt.memfault.com/blog/) | 每篇文章都值得精读 |
| [STM32 中文社区](https://shequ.stmicroelectronics.cn/) | ST 官方中文社区 |
| [Embedded Artistry](https://embeddedartistry.com/) | 嵌入式软件工程最佳实践 |
| [Hackaday](https://hackaday.com/) | 硬件黑客项目灵感 |
| EEVblog Forum | 硬件调试求助 |

---

> **最后的话**：花 ¥150 买一块 STM32 Nucleo 板 + 一个逻辑分析仪克隆版，用一个月时间让一个 LED 按你想象的方式闪烁。如果你觉得"这比写 CRUD 有意思多了"，那嵌入式就适合你。
>
> 如果觉得硬件调试太折腾，Embedded Linux 应用层（结合你未来的 Go 技能）是更好的切入点——你仍然在嵌入式行业，但不需要每天和数据手册的寄存器表格搏斗。
>
> **无论哪条路，C 语言都是门票。没有 C，就没有嵌入式。**
