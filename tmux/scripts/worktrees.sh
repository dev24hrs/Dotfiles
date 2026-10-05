#!/usr/bin/env bash
set -euo pipefail

# worktree.sh: 列出当前 repo 的全部 worktree 分支,切换或新建同名 tmux session
#
# 由 tmux.conf 调用:
#   bind y display-popup -d "#{pane_current_path}" -w 40% -h 40% \
#     -E "$HOME/.config/tmux/scripts/worktree_switcher.sh"
#
# fzf 列表来自 `git worktree list`(含主 worktree)+ "[new branch]" 项;
# 新建分支的 worktree 放在 <repo 根>/.worktrees/<分支名> 下
# session 命名规则: <repo 名>-<分支名>(如 projecta-featurea),防止多 repo 同分支名冲突
# tmux target 中 '.' ':' 是 window/pane 分隔符,session 名中的 . : / 空格统一替换为 _

start_dir="${1:-$PWD}"
client_name="${2:-}"

# 主 worktree 总是 `git worktree list` 的第一条,其路径即 repo 根
# (在 linked worktree 内,rev-parse --show-toplevel 返回的是 worktree 根,不能直接用)
# git 在非 repo 目录下会以 128 失败,`|| true` 保证 set -e 不提前终止,走到下面的友好提示
repo_root=$(git -C "$start_dir" worktree list --porcelain 2>/dev/null |
  awk '/^worktree / { print $2; exit }') || true
if [ -z "$repo_root" ]; then
  echo "Not inside a git repo: $start_dir"
  read -r -p "Press enter to close..."
  exit 1
fi
repo_name=$(basename "$repo_root")

git -C "$repo_root" worktree prune 2>/dev/null || true

# 只列出挂在分支上的 worktree;detached HEAD 的 worktree 不参与切换
branches=$(git -C "$repo_root" worktree list --porcelain |
  awk '/^branch refs\/heads\// { sub(/^branch refs\/heads\//, ""); print }' | sort -u)
selection=$(printf '%s\n[new branch]\n' "$branches" |
  fzf --height 100% --prompt="Branch> " --header "$repo_name" --preview-window hidden --no-border)
[ -z "$selection" ] && exit 0

if [ "$selection" = "[new branch]" ]; then
  read -r -p "New branch name: " branch
  [ -z "$branch" ] && exit 0
  is_new=true
else
  branch="$selection"
  is_new=false
fi

wt_root="$repo_root/.worktrees"
mkdir -p "$wt_root"
if ! grep -qxF '.worktrees/' "$repo_root/.gitignore" 2>/dev/null; then
  echo '.worktrees/' >>"$repo_root/.gitignore"
fi

existing_path=$(git -C "$repo_root" worktree list --porcelain | awk -v b="refs/heads/$branch" '
  /^worktree / { path=$2 }
  $0 == "branch " b { print path }
')

if [ -n "$existing_path" ]; then
  wt_path="$existing_path"
elif [ -e "$wt_root/$branch" ]; then
  echo "Path exists but isn't a registered worktree: $wt_root/$branch"
  read -r -p "Press enter to close..."
  exit 1
else
  # 分支名可能含 '/',worktree add 需要父目录存在
  mkdir -p "$(dirname "$wt_root/$branch")"
  if [ "$is_new" = true ]; then
    git -C "$repo_root" worktree add "$wt_root/$branch" -b "$branch" || {
      read -r -p "Press enter to close..."
      exit 1
    }
  else
    git -C "$repo_root" worktree add "$wt_root/$branch" "$branch" || {
      read -r -p "Press enter to close..."
      exit 1
    }
  fi
  wt_path="$wt_root/$branch"
fi

sanitized_branch=$(echo "$branch" | tr '.:/ ' '____')
sess_name="${repo_name}-${sanitized_branch}"

if ! tmux has-session -t "$sess_name" 2>/dev/null; then
  tmux new-session -d -s "$sess_name" -c "$wt_path" || {
    read -r -p "Press enter to close..."
    exit 1
  }
fi

if [ -z "${TMUX:-}" ]; then
  tmux attach -t "$sess_name"
elif [ -n "$client_name" ]; then
  tmux switch-client -c "$client_name" -t "$sess_name"
else
  tmux switch-client -t "$sess_name"
fi
