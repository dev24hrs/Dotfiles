#!/usr/bin/env bash
set -euo pipefail

# worktrees.sh: 列出当前 repo 的全部 worktree 分支,选中后交由 worktrunk(wt) 切换/新建。
# fzf 列表来自 `git worktree list`(含主 worktree)+ "[new branch]" 项;
# session 创建/切换/清理全部由 wt hooks 完成(refer to worktrunk/config.toml):
#   - new/switch 后确保 tmux session 存在并 switch-client,命名 {{ repo }}-{{ branch | sanitize }}
#   - remove 后 kill 对应 session
# 脚本自身不管理 tmux session、不执行 worktree add、不修改 .gitignore
# (worktree 路径由 worktrunk 的 worktree-path 决定;.worktrees/ 已入全局 gitignore)。
#
# 由 tmux.conf 调用:
#   bind y display-popup -d "#{pane_current_path}" -w 40% -h 40% \
#     -E "$HOME/.config/tmux/scripts/worktrees.sh"

start_dir="${1:-$PWD}"

# display-popup -E 在命令退出后立即关闭 popup;出错时阻塞在 read 上让信息可见
die() {
  if [ $# -gt 0 ]; then
    printf '%s\n' "$*" >&2
  fi
  if [ -t 0 ]; then
    read -r -p "Press enter to close..." || true
  fi
  exit 1
}

for cmd in git fzf wt; do
  command -v "$cmd" >/dev/null 2>&1 || die "$cmd not found in PATH"
done

cd "$start_dir" 2>/dev/null || die "Not a directory: $start_dir"

# 主 worktree 是 `git worktree list` 的第一条(git 文档保证),其路径即仓库根;
# 在 linked worktree 内 rev-parse --show-toplevel 返回的是该 worktree 根,不能用来找仓库根
worktrees=$(git worktree list --porcelain 2>/dev/null) || true
repo_root=$(printf '%s\n' "$worktrees" | awk '/^worktree / { print substr($0, 10); exit }')
[ -n "$repo_root" ] || die "Not inside a git repo: $start_dir"
repo_name=${repo_root##*/}

# 清理目录已删除的 worktree 记录(默认过期策略,不误伤临时离线的卷)
git worktree prune 2>/dev/null || true

# 当前所在 worktree,用于列表标记(在 linked worktree 内即为该 worktree 根)
current_root=$(git rev-parse --show-toplevel 2>/dev/null) || true

# 每行:分支名;当前所在 worktree 追加 \t(current)。[new branch] 追加在末尾。
# detached HEAD(无 branch 行)与 prunable(目录已删)条目跳过
list=$(printf '%s\n' "$worktrees" | awk -v cur="$current_root" '
  function flush() {
    if (have && branch != "" && !prunable) {
      printf "%s%s\n", branch, (path == cur ? "\t(current)" : "")
    }
    have = 0; branch = ""
  }
  /^worktree / { flush(); path = substr($0, 10); have = 1; prunable = 0; next }
  /^branch /   { branch = substr($0, 8); sub(/^refs\/heads\//, "", branch); next }
  /^prunable/  { prunable = 1; next }
  /^$/         { flush(); next }
  END          { flush(); print "[new branch]" }
')

selection=$(printf '%s\n' "$list" |
  fzf --height 100% --no-border --prompt="Branch> " --header "$repo_name" \
    --preview-window hidden) || true
[ -n "$selection" ] || exit 0

branch=${selection%%$'\t'*}

if [ "$branch" = "[new branch]" ]; then
  if ! read -r -p "New branch name: " branch; then
    exit 0
  fi
  [ -n "$branch" ] || exit 0
  # 注意不能写成 `--branch -- "$branch"`:git 会把 -- 当作 --branch 的值直接 usage error(exit 129)
  git check-ref-format --branch "$branch" >/dev/null 2>&1 || die "Invalid branch name: $branch"

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    # 分支已存在、只是还没有 worktree:普通 switch,wt 会补建 worktree(已实测)
    wt switch "$branch" || die
  else
    # --create 的 base 默认为默认分支(main),与 wt 交互式行为一致
    wt switch --create "$branch" || die
  fi
else
  wt switch "$branch" || die
fi
