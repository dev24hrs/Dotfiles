# Tmux

![](https://github.com/dev24hrs/Dotfiles/blob/main/img/tmux_with_pane.png?raw=true)

## Install

```bash
brew install tmux --HEAD
mkdir -p ~/.config/tmux
```

## TPM (Plugin Manager)

```bash
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
```

| Key            | Desc              |
| :------------- | :---------------- |
| `prefix + I`   | Install plugins   |
| `prefix + U`   | Update plugins    |
| `prefix + M-u` | Uninstall plugins |

## Usage

每个 session 可以有多个 window，每个 window 可以有多个 pane。

1. `tmux new -s <name>` 新建 session
2. `prefix + r` 重命名当前 window（预填当前名）
3. `prefix + c` 新建 window
4. `prefix + p` / `prefix + n` / `prefix + 0-9` 切换 window
5. `prefix + -` / `prefix + =` 横向/竖向分 pane
6. `C-h/j/k/l` 在 pane 间跳转（无需 prefix）
7. `prefix + x` 关闭当前 pane
8. `prefix + q` 关闭当前 window
9. `prefix + w` 列出所有 window
10. `prefix + d` 暂离 session
11. `tmux a -t <name>` 重连 session

---

## Keybindings

### Session

| Key          | Desc             |
| :----------- | :--------------- |
| `prefix + s` | 列出所有 session |
| `prefix + $` | 重命名 session   |
| `prefix + d` | detach session   |
| `prefix + N` | 新建 session     |
| `prefix + ,` | reload 配置文件  |

### Window

| Key             | Desc                    |
| :-------------- | :---------------------- |
| `prefix + w`    | 列出所有 window         |
| `prefix + c`    | 新建 window             |
| `prefix + r`    | 重命名 window（预填名） |
| `prefix + q`    | 关闭当前 window         |
| `prefix + p`    | 上一个 window           |
| `prefix + n`    | 下一个 window           |
| `prefix + 0-9`  | 跳到指定 window         |
| `S-Left / M-h`  | 上一个 window           |
| `S-Right / M-l` | 下一个 window           |

### Pane

| Key                     | Desc                        |
| :---------------------- | :-------------------------- |
| `C-h / C-j / C-k / C-l` | 切换 pane（左/下/上/右）    |
| `prefix + -`            | 横向分 pane（保持当前目录） |
| `prefix + =`            | 竖向分 pane（保持当前目录） |
| `prefix + x`            | 关闭当前 pane（无需确认）   |
| `prefix + C-l`          | 清屏（透传 C-l 给 shell）   |

**Pane 标题栏**: 顶部显示，由 `pane_starship.sh` 脚本渲染（显示路径、git branch 等信息）。

活跃 pane 边框为紫色 (`#b294bb`)，非活跃为灰色。

- 路径、git branch 等信息通过 `pane_starship.sh` & `starship-tmux.toml` 渲染获取
- Sidebar pane 自动隐藏标题内容（通过 `@is_sidebar` 条件判断），保留细线边框

### Agent Sidebar

`prefix + \` 在左侧 dock 一个双面板 sidebar（30 列宽），上半部分显示所有 tmux session，下半部分显示所有 AI agent pane。两个面板均 1s 自动刷新。

| 操作      | 功能                          |
| :-------- | :---------------------------- |
| `j` / `↓` | 光标下移                      |
| `k` / `↑` | 光标上移                      |
| `Enter`   | 跳转到选中 session / agent pane |
| `q`       | 关闭 sidebar                  |

**上半部分（Sessions）**：列出所有 tmux session，显示名称、window 数和 attach 状态，光标自动跟随当前 attached session。

**下半部分（Agents）**：列出所有 `claude` pane，检测工作状态（通过抓屏匹配 timer 模式），光标自动跟随当前活跃 pane。

每个 agent 条目显示：状态（`idle` / `working`）、session 名与 pane 标题。

| 状态      | 颜色   | 含义     |
| :-------- | :----- | :------- |
| `idle`    | 绿色   | 空闲     |
| `working` | 黄色   | 正在处理 |

**实现文件**:
- `scripts/tmux-sidebar.sh` — 创建/关闭 sidebar（split-window -hbf，上下分两个 pane）
- `scripts/sidebar-sessions.sh` — 上半部分 TUI（session 列表、键盘导航、1s 刷新）
- `scripts/sidebar-claude.sh` — 下半部分 TUI（agent 列表、键盘导航、1s 刷新）

### Popup

| Key          | Desc                       |
| :----------- | :------------------------- |
| `prefix + g` | lazygit (80% 窗口)         |
| `prefix + t` | fish terminal (60% 窗口)   |
| `prefix + y` | Agent 多选弹出窗 (60% 窗口) |
| `prefix + u` | Git worktree 管理 (60% 窗口) |
| `prefix + \` | Agent sidebar (左侧 dock)  |

### Copy Mode (Vi)

| Key          | Desc             |
| :----------- | :--------------- |
| `prefix + v` | 进入 copy mode   |
| `v`          | 开始选择         |
| `V`          | 选择整行         |
| `C-v`        | 矩形选择         |
| `y`          | 复制到系统剪贴板 |
| `Y`          | 复制整行         |
| `Escape`     | 取消选择         |

### Session CLI

| Cmd                           | Desc             |
| :---------------------------- | :--------------- |
| `tmux new -s <name>`          | 新建 session     |
| `tmux ls`                     | 列出所有 session |
| `tmux a -t <name>`            | 重连 session     |
| `tmux kill-session -t <name>` | 删除 session     |
