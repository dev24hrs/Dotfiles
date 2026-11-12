# Worktrunk

[worktrunk](https://worktrunk.dev) 提供 `wt` 命令管理 git worktree; 本仓库用它把 worktree 与 tmux session 打通:

- `wt switch` 切换/新建 worktree 后, hook 自动确保对应 session 存在(`<repo>-<branch>`, 单窗口 `dev` + 左右 2 pane)并切入
- `wt remove` 删除 worktree 后, hook 自动清理该 session

配置: [worktrunk/config.toml](https://github.com/x3m4g63/Dotfiles/blob/main/worktrunk/config.toml)(已加入 config.map, symlink 到 `~/.config/worktrunk/`)

### 安装

```bash
brew install worktrunk
```

### 配置(config.toml)

```toml
# worktree 统一放在 <repo>/.worktrees/<branch>(已入全局 .gitignore)
worktree-path = "{{ repo_path }}/.worktrees/{{ branch | sanitize }}"

# 导航交由 tmux hook 完成: 发起切换的 shell 原地不动(--cd 可单次覆盖)
[switch]
cd = false

# post-switch 每次切换(后台): session 不存在则建(左右 2-pane 工作区), 然后切入
# post-remove: remove 后清理该 session
[post-switch]
tmux = '''
S={{ repo }}-{{ branch | sanitize }}
W={{ worktree_path }}
if ! tmux has-session -t "$S" 2>/dev/null; then
  left=$(tmux new-session -d -s "$S" -c "$W" -n dev -P -F '#{pane_id}')
  tmux split-window -h -t "$left" -c "$W"
  tmux select-pane -t "$left"
fi
if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "$S"
fi
'''

[post-remove]
tmux = 'tmux kill-session -t {{ repo }}-{{ branch | sanitize }} 2>/dev/null || true'
```

### 命令使用

```bash
wt switch <branch>            # 切换已有分支(worktree 不存在时自动补建), 并切入对应 session
wt switch --create <branch>   # 新建分支 + worktree(base 默认 main), 同样自动建 session
wt switch --branches          # 交互式 picker, 包含尚无 worktree 的分支
wt list                       # 列出所有 worktree 及状态
wt remove [branch]            # 删除 worktree(已合并则删分支)并清理 session
wt merge [target]             # squash + rebase + fast-forward 合并进 target
```

fish 的补全与 shell 集成: `fish/functions/wt.fish`、`fish/completions/wt.fish`。

### 相关流程

- tmux 内: `prefix + w` 打开 fzf worktree 选择器(`tmux/scripts/worktrees.sh`), 选中后交由 `wt switch` / `wt switch --create`(见 tmux/README.md「Worktree 集成」)
- 手动: fish 命令 `dev tmux [session-name]` 新建/进入同款 session(命名规则与 hooks 一致, 见 fish/README.md)
