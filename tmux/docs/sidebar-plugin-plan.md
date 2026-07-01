# tmux-sidebar 插件发布方案

## 目标

将当前 dotfiles 私有的 sidebar 脚本发布为独立 GitHub 仓库 `dev24hrs/tmux-sidebar`，让其他人通过 TPM（Tmux Plugin Manager）安装使用。

## 仓库结构

```
tmux-sidebar/
├── .gitignore
├── LICENSE.md
├── README.md
├── sidebar.tmux            # TPM 入口（chmod +x）
└── scripts/
    ├── sidebar.sh           # 编排器（原 tmux-sidebar.sh）
    ├── sidebar-sessions.sh  # Session 列表面板
    ├── sidebar-agents.sh    # Agent 列表面板（原 sidebar-claude.sh）
    └── helpers.sh           # 共享函数库（NEW）
```

## 设计决策

1. **Agent 面板默认开启，可配置关闭**：`@sidebar-agents-enable` 默认 `1`，设为 `0` 只显示 session 面板
2. **Agent 检测命令可配置**：`@sidebar-agent-commands` 默认 `"claude"`，空格分隔支持多个命令（如 `"claude code copilot"`）
3. **pane-border-format**：插件仅在当前 format 为空（tmux 默认值）时设置最小格式；用户已有自定义格式时，README 指导自行添加 `#{?@is_sidebar,,...}` 包裹
4. **最小 tmux 版本**：3.0+
5. **颜色可配置**：通过 `@sidebar-main-color` / `@sidebar-accent-color` 等选项，提供合理默认值

## 用户配置项

| 选项                      | 默认值        | 说明                          |
| ------------------------- | ------------- | ----------------------------- |
| `@sidebar-width`          | `30`          | Sidebar 宽度（列数）          |
| `@sidebar-agents-enable`  | `1`           | 是否显示 Agent 面板           |
| `@sidebar-agent-commands` | `"claude"`    | 要检测的 agent 命令，空格分隔 |
| `@sidebar-key`            | `"\\"`        | 切换 sidebar 的按键           |
| `@sidebar-main-color`     | `"#7a9a5e"`   | 主色调（idle/已 attach）      |
| `@sidebar-accent-color`   | `"#dbbc7f"`   | 强调色（working）             |
| `@sidebar-dim-color`      | `"colour242"` | 暗淡文字颜色                  |

## 各文件要点

### 1. `sidebar.tmux` — TPM 入口（新建）

TPM 会执行插件根目录下所有 `*.tmux` 文件。该文件负责：

- 用 `CURRENT_DIR` 模式解析插件路径（适配任意 TPM 安装位置）
- `tmux set-option -gq` 写入默认选项（不覆盖用户已设值）
- `tmux bind-key` 绑定 `@sidebar-key` → `run-shell $CURRENT_DIR/scripts/sidebar.sh`
- 仅当 `pane-border-format` 为空时设置最小格式

```bash
#!/usr/bin/env bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

tmux set-option -gq @sidebar-width "30"
tmux set-option -gq @sidebar-agents-enable "1"
tmux set-option -gq @sidebar-agent-commands "claude"
tmux set-option -gq @sidebar-main-color "#7a9a5e"
tmux set-option -gq @sidebar-accent-color "#dbbc7f"
tmux set-option -gq @sidebar-dim-color "colour242"
tmux set-option -gq @sidebar-key "\\"

sidebar_key="$(tmux show-option -gqv @sidebar-key)"
tmux bind-key "$sidebar_key" run-shell "$CURRENT_DIR/scripts/sidebar.sh"

current_format="$(tmux show-option -gqv pane-border-format)"
if [ -z "$current_format" ]; then
  tmux set-option -g pane-border-format \
    '#{?@is_sidebar, , #{session_name}:#{window_index}.#{pane_index} }'
fi
```

### 2. `scripts/helpers.sh` — 共享函数库（新建）

DRY 掉两个 TUI 脚本中重复的 `close_sidebar`、颜色转换、状态读取逻辑。

```bash
#!/usr/bin/env bash

get_tmux_option() {
  local option="$1"
  local default="$2"
  local value
  value="$(tmux show-option -gqv "$option" 2>/dev/null)"
  echo "${value:-$default}"
}

hex_to_ansi_fg() {
  local hex="$1"
  hex="${hex#'#'}"
  printf '\033[38;2;%d;%d;%dm' \
    "$((16#${hex:0:2}))" "$((16#${hex:2:2}))" "$((16#${hex:4:2}))"
}

close_sidebar() {
  printf '\033[?25h'
  local cur
  cur="$(tmux display -p '#{pane_id}')"
  tmux list-panes -F '#{pane_id} #{@is_sidebar}' | \
    awk '$2==1{print $1}' | while read -r p; do
    [ "$p" != "$cur" ] && tmux kill-pane -t "$p" 2>/dev/null
  done
  tmux kill-pane
  exit 0
}

read_agent_state() {
  local pane_id="$1"
  # 优先级：claude-state 文件 → agent-state 文件 → pane 抓屏 fallback
  for f in "/tmp/claude-state-$pane_id" "/tmp/agent-state-$pane_id"; do
    if [ -f "$f" ]; then
      cat "$f"
      return
    fi
  done
  if tmux capture-pane -t "$pane_id" -p -S -20 2>/dev/null | \
    grep -qE '\(([0-9]+m ?)?[0-9]+s'; then
    echo "working"
  else
    echo "idle"
  fi
}
```

### 3. `scripts/sidebar.sh` — 编排器（改自 tmux-sidebar.sh）

| 原来                                             | 改为                                      |
| ------------------------------------------------ | ----------------------------------------- |
| `$HOME/.config/tmux/scripts/sidebar-sessions.sh` | `$CURRENT_DIR/sidebar-sessions.sh`        |
| `-l 30` 硬编码                                   | `$(tmux show-option -gqv @sidebar-width)` |
| 始终创建 agent 面板                              | 根据 `@sidebar-agents-enable` 条件创建    |

其余逻辑不变：通过 `@is_sidebar` 查找/销毁已有 sidebar、创建两个垂直 pane、归还焦点到主 pane。

### 4. `scripts/sidebar-sessions.sh` — Session 面板（改自 sidebar-sessions.sh）

| 原来                   | 改为                                                          |
| ---------------------- | ------------------------------------------------------------- |
| 内联 ANSI 颜色常量     | source `helpers.sh`，从 tmux 选项读取 + `hex_to_ansi_fg` 转换 |
| 内联 `close_sidebar()` | source `helpers.sh`，删除本地定义                             |

其余逻辑不变：j/k 导航、Enter 切换 session、1s 自动刷新、光标自动跟随 attached session。

### 5. `scripts/sidebar-agents.sh` — Agent 面板（改自 sidebar-claude.sh）

| 原来                            | 改为                                                    |
| ------------------------------- | ------------------------------------------------------- |
| `[ "$cmd" != "claude" ]` 硬编码 | 从 `@sidebar-agent-commands` 读取空格分隔列表，循环匹配 |
| 内联 `agent_state()` 抓屏函数   | 调用 `helpers.sh` 的 `read_agent_state`                 |
| 内联 `close_sidebar()`          | source `helpers.sh`，删除本地定义                       |
| 内联 ANSI 颜色常量              | 同 sessions 脚本，从选项读取                            |

## 实施顺序

1. 创建仓库目录结构
2. 写 `helpers.sh`
3. 写 `sidebar.tmux`
4. 改 `sidebar-sessions.sh`
5. 改 `sidebar-agents.sh`
6. 改 `sidebar.sh`
7. 写 `README.md`、`LICENSE.md`、`.gitignore`
8. 推送到 GitHub

## dotfiles 迁移

迁移后 `tmux.conf` 的改动：

- **删除** `bind-key \\ run-shell "$HOME/.config/tmux/scripts/tmux-sidebar.sh"`
- **添加** `set -g @plugin 'dev24hrs/tmux-sidebar'` 到插件列表
- **pane-border-format** 保留现有的 starship 格式不变（已含 `@is_sidebar` 判断，插件检测到已有值不覆盖）
- **删除** `tmux/scripts/tmux-sidebar.sh`、`sidebar-sessions.sh`、`sidebar-claude.sh`（这些文件已在插件仓库中）

## TPM 安装方式

用户只需在 `tmux.conf` 中添加：

```tmux
set -g @plugin 'dev24hrs/tmux-sidebar'
```

然后按 `Prefix + I` 安装。按 `Prefix + \` 切换 sidebar。

可选配置示例：

```tmux
set -g @sidebar-width "35"
set -g @sidebar-agent-commands "claude code"
set -g @sidebar-main-color "#89b482"
set -g @sidebar-accent-color "#e5c890"
```
