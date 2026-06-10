#!/bin/bash
set -e

DOTFILES_DIR="$HOME/Documents/Dotfiles"

# ── 配置映射 ──────────────────────────────────────────────────────────────────
# 单一数据源,格式: <dotfiles 内的相对路径>:<目标绝对路径>
# setup_symlinks 和 migrate_to_dotfiles 都基于这个清单工作

CONFIG_MAP=(
  "tmux:$HOME/.config/tmux"
  "fish:$HOME/.config/fish"
  "nvim:$HOME/.config/nvim"
  "git/.gitconfig:$HOME/.gitconfig"
  "git/.gitignore_global:$HOME/.gitignore_global"
  "ghostty:$HOME/.config/ghostty"
  "bat:$HOME/.config/bat"
  "starship:$HOME/.config/starship"
  "lazygit:$HOME/.config/lazygit"
  "wezterm:$HOME/.config/wezterm"
  "yazi:$HOME/.config/yazi"
  "go-musicfox:$HOME/.config/go-musicfox"
)

# ── 工具函数 ──────────────────────────────────────────────────────────────────

ok() { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }
err() { echo "  ✗ $1" >&2; }

backup_path() { echo "${1}.bak.$(date +%Y%m%d%H%M%S)"; }

make_link() {
  local src="$1"  # Dotfiles 里的源路径
  local dest="$2" # 目标路径 (~/.config/xxx 或 ~/.xxx)

  # 源不存在则跳过
  if [ ! -e "$src" ]; then
    warn "source not found, skipping: $src"
    return 0
  fi

  # 已经是正确的 symlink，跳过(用 readlink -f 比较规范化路径,容忍尾斜杠等差异)
  if [ -L "$dest" ] && [ "$(readlink -f "$dest" 2>/dev/null)" = "$(readlink -f "$src" 2>/dev/null)" ]; then
    ok "already linked: $dest"
    return 0
  fi

  # 目标存在但不是 symlink（真实文件/目录），带时间戳备份
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    local backup
    backup="$(backup_path "$dest")"
    warn "backing up existing: $dest -> $backup"
    mv "$dest" "$backup"
  fi

  # 删掉旧的错误 symlink(给出当前指向以便排障)
  if [ -L "$dest" ]; then
    warn "removing stale symlink: $dest -> $(readlink "$dest")"
    rm "$dest"
  fi

  # 父目录不存在才创建,避免无谓 syscall
  local parent
  parent="$(dirname "$dest")"
  [ -d "$parent" ] || mkdir -p "$parent"

  ln -s "$src" "$dest"
  ok "linked: $dest -> $src"
}

# ── Symlinks ──────────────────────────────────────────────────────────────────
setup_symlinks() {
  echo "→ Setting up symlinks..."
  local entry src dest
  for entry in "${CONFIG_MAP[@]}"; do
    src="${entry%%:*}"
    dest="${entry#*:}"
    make_link "$DOTFILES_DIR/$src" "$dest"
  done
  echo ""
}

# ── migrate ──────────────────────────────────────────────────────────────────
# 把现有的 ~/.config/xxx (或 ~/.xxx) 物理移动到 Dotfiles,然后建立软链
# 适用场景:第一次接入 Dotfiles,本地已有配置,想把它们纳入版本管理
migrate_to_dotfiles() {
  echo "→ Migrating existing configs into Dotfiles..."
  local entry src_rel dest src
  local migrated=0 skipped=0 failed=0

  for entry in "${CONFIG_MAP[@]}"; do
    src_rel="${entry%%:*}"
    dest="${entry#*:}"
    src="$DOTFILES_DIR/$src_rel"

    # 目标根本不存在,无需迁移
    if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
      warn "not present, skipping: $dest"
      skipped=$((skipped + 1))
      continue
    fi

    # 目标已经是 symlink,说明已被管理(或被指到别处),不迁移
    if [ -L "$dest" ]; then
      warn "already a symlink, skipping: $dest -> $(readlink "$dest")"
      skipped=$((skipped + 1))
      continue
    fi

    # Dotfiles 里已存在同名内容:不能盲目覆盖,先备份再迁移
    if [ -e "$src" ]; then
      local backup
      backup="$(backup_path "$src")"
      warn "dotfiles already has: $src -> backup to $backup"
      mv "$src" "$backup"
    fi

    # 确保 Dotfiles 里父目录存在(如 git/.gitconfig 需要 git/ 已存在)
    local parent
    parent="$(dirname "$src")"
    [ -d "$parent" ] || mkdir -p "$parent"

    # 真正迁移
    if mv "$dest" "$src"; then
      ok "migrated: $dest -> $src"
      migrated=$((migrated + 1))
    else
      err "failed to migrate: $dest -> $src"
      failed=$((failed + 1))
    fi
  done

  echo ""
  echo "  summary: migrated=$migrated skipped=$skipped failed=$failed"
  echo ""

  # 仅在确实迁移过且无失败时,自动重建软链
  if [ "$failed" -gt 0 ]; then
    err "migration had failures, NOT running setup_symlinks automatically"
    return 1
  fi
  if [ "$migrated" -eq 0 ]; then
    echo "  nothing migrated, skip setup_symlinks"
    return 0
  fi
  setup_symlinks
}

# ── 增量添加 ──────────────────────────────────────────────────────────────────

# 把 Dotfiles 里的某个目录/文件软链到合适的位置
# 用法: add_config <dotfiles-path>
#   .* 开头的链到 $HOME (如 .gitconfig)
#   其它链到 ~/.config/<name>
add_config() {
  local src="$1"

  if [ -z "$src" ]; then
    err "usage: $0 add <path-in-dotfiles>"
    err "example: $0 add $DOTFILES_DIR/yazi"
    exit 1
  fi

  # 展开 ~ 并解析为绝对路径
  src="${src/#\~/$HOME}"

  if [ ! -e "$src" ]; then
    err "source not found: $src"
    exit 1
  fi

  local name
  name="$(basename "$src")"

  local dest
  case "$name" in
  .*) dest="$HOME/$name" ;;
  *) dest="$HOME/.config/$name" ;;
  esac

  echo "→ Adding new symlink..."
  make_link "$src" "$dest"
  echo ""
  echo "  记得在 cfg.sh 的 CONFIG_MAP 里新增一行："
  echo "  \"${src#"$DOTFILES_DIR"/}:$dest\""
  echo ""
  echo "  然后提交："
  echo "  cd $DOTFILES_DIR && git add $name && git commit -m 'feat: add $name config'"
}

# ── 入口 ──────────────────────────────────────────────────────────────────────

usage() {
  echo "Usage: $0 <command> [args]"
  echo "  symlinks         - symlinks existing Dotfiles to new ~/.config"
  echo "  migrate          - migrate existing ~/.config to new Dotfiles"
  echo "  add <src>        - add new Dotfiles symlink to ~/.config (or \$HOME for dotfiles)"
  exit 1
}

case "${1:-}" in
symlinks) setup_symlinks ;; # ./cfg.sh symlinks
add)
  shift
  add_config "$1"
  ;;                            # ./cfg.sh add ~/Documents/Dotfiles/yazi
migrate) migrate_to_dotfiles ;; # ./cfg.sh migrate
*) usage ;;
esac
