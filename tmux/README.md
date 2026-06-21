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

**Pane 标题栏**: 顶部显示，由 `pane_starship.sh` 脚本渲染（显示claude status、路径、git branch 等信息）。

活跃 pane 边框为紫色 (`#b294bb`)，非活跃为灰色。

- 路径、git branch等信息通过`pane_starship.sh` & `starship-tmux.toml` 渲染获取
- claude status信息通过`claude-status.sh` & [claude hooks](https://github.com/dev24hrs/Dotfiles/blob/main/claude/settings.json) 获取

### Popup

| Key          | Desc                     |
| :----------- | :----------------------- |
| `prefix + g` | lazygit (80% 窗口)       |
| `prefix + t` | fish terminal (60% 窗口) |
| `prefix + u` | Claude 实例选择器 (fzf)  |

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
