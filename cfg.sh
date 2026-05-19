#!/bin/bash
set -e

DOTFILES_DIR="$HOME/Documents/Dotfiles"

# ── 工具函数 ──────────────────────────────────────────────────────────────────

log() { echo "  $1"; }
ok() { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }

# 创建 symlink，目标已存在则备份后替换
make_link() {
  local src="$1"  # Dotfiles 里的源路径
  local dest="$2" # 目标路径 (~/.config/xxx 或 ~/.xxx)

  # 源不存在则跳过
  if [ ! -e "$src" ]; then
    warn "source not found, skipping: $src"
    return
  fi

  # 已经是正确的 symlink，跳过
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    ok "already linked: $dest"
    return
  fi

  # 目标存在但不是 symlink（真实文件/目录），备份
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    warn "backing up existing: $dest -> ${dest}.bak"
    mv "$dest" "${dest}.bak"
  fi

  # 删掉旧的错误 symlink
  [ -L "$dest" ] && rm "$dest"

  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  ok "linked: $dest -> $src"
}

# ── Symlinks ──────────────────────────────────────────────────────────────────

setup_symlinks() {
  echo "→ Setting up symlinks..."

  # tmux
  make_link "$DOTFILES_DIR/tmux" "$HOME/.config/tmux"

  # fish
  make_link "$DOTFILES_DIR/fish" "$HOME/.config/fish"

  # neovim
  make_link "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

  # git
  make_link "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
  make_link "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"

  # ghostty
  make_link "$DOTFILES_DIR/ghostty" "$HOME/.config/ghostty"

  # bat
  make_link "$DOTFILES_DIR/bat" "$HOME/.config/bat"

  # starship
  make_link "$DOTFILES_DIR/starship" "$HOME/.config/starship"
  # lazygit
  make_link "$DOTFILES_DIR/lazygit" "$HOME/.config/lazygit"

  # hammerspoon
  make_link "$DOTFILES_DIR/hammerspoon" "$HOME/.hammerspoon"

  # wezterm
  make_link "$DOTFILES_DIR/wezterm" "$HOME/.config/wezterm"

  # yazi
  make_link "$DOTFILES_DIR/yazi" "$HOME/.config/yazi"

  # go-musicfox
  make_link "$DOTFILES_DIR/go-musicfox" "$HOME/.config/go-musicfox"
  echo ""
}

# ── 额外配置 ──────────────────────────────────────────────────────────────────
setup_tmux() {
  echo "→ Configuring tmux..."

  # 安装 TPM
  TPM_DIR="$HOME/.config/tmux/plugins/tpm"
  if [ ! -d "$TPM_DIR" ]; then
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    ok "TPM cloned"
  else
    ok "TPM already installed"
  fi

  # 安装插件（headless）
  tmux new-session -d -s cfg_setup 2>/dev/null || true
  TMUX_PLUGIN_MANAGER_PATH="$HOME/.config/tmux/plugins" \
    "$TPM_DIR/bin/install_plugins"
  tmux kill-session -t cfg_setup 2>/dev/null || true
  ok "tmux plugins installed"

  echo ""
}

setup_git() {
  echo "→ Configuring git..."

  # 全局 gitignore 注册
  git config --global core.excludesfile "$HOME/.config/git/.gitignore_global"
  ok "global gitignore set"

  echo ""
}

# 用法：./cfg.sh add <配置目录或文件的现有路径>
# 示例：./cfg.sh add ~/.config/yazi

add_config() {
  local target="$1" # 已存在的配置路径，如 ~/.config/yazi

  # 转换为绝对路径
  target="$(cd "$(dirname "$target")" && pwd)/$(basename "$target")"

  # 推导在 Dotfiles 里的对应位置
  # ~/.config/yazi -> ~/Dotfiles/yazi
  # ~/.npmrc       -> ~/Dotfiles/npm/.npmrc (需手动指定)
  local name
  name="$(basename "$target")"
  local dest="$DOTFILES_DIR/$name"

  if [ -e "$dest" ]; then
    warn "already exists in Dotfiles: $dest"
    return
  fi

  # 移动真实文件到 Dotfiles
  mv "$target" "$dest"
  ok "moved: $target -> $dest"

  # 建立 symlink
  make_link "$dest" "$target"

  echo ""
  echo "  记得在 cfg.sh 的 setup_symlinks() 里补上这行："
  echo "  make_link \"\$DOTFILES_DIR/$name\" \"$target\""
  echo ""
  echo "  然后提交："
  echo "  cd ~/Dotfiles && git add $name && git commit -m 'feat: add $name config'"
}

migrate_all() {
  echo "→ Migrating existing ~/.config dirs to Dotfiles..."

  # 需要纳入管理的目录列表
  local configs=(
    "$HOME/.config/tmux"
    "$HOME/.config/fish"
    "$HOME/.config/nvim"
    "$HOME/.config/ghostty"
    "$HOME/.config/wezterm"
    "$HOME/.config/bat"
    "$HOME/.config/lazygit"
    "$HOME/.config/starship"
    "$HOME/.hammerspoon"
    "$HOME/.gitconfig"
    "$HOME/.gitignore_global"
    "$HOME/.config/go-musicfox"
    "$HOME/.config/yazi"
  )

  for target in "${configs[@]}"; do
    local name
    name="$(basename "$target")"
    local dest="$DOTFILES_DIR/$name"

    # 已经是 symlink，跳过
    if [ -L "$target" ]; then
      ok "already a symlink, skipping: $target"
      continue
    fi

    # 源不存在，跳过
    if [ ! -e "$target" ]; then
      warn "not found, skipping: $target"
      continue
    fi

    # Dotfiles 里已有同名，备份后覆盖
    if [ -e "$dest" ]; then
      warn "conflict in Dotfiles, backing up: $dest -> ${dest}.bak"
      mv "$dest" "${dest}.bak"
    fi

    # 移动真实文件/目录到 Dotfiles
    mv "$target" "$dest"
    ok "moved: $target -> $dest"

    # 建立 symlink
    ln -s "$dest" "$target"
    ok "linked: $target -> $dest"

    echo ""
  done

  echo "✓ Migration done!"
  echo ""
  echo "  记得提交："
  echo "  cd ~/Dotfiles && git add . && git commit -m 'chore: migrate existing configs'"
}

# ── 入口 ──────────────────────────────────────────────────────────────────────

usage() {
  echo "Usage: $0 <command>"
  echo "  all       - 执行全部配置（symlinks + 各工具配置）"
  echo "  symlinks  - 只建立 symlinks"
  echo "  tmux      - 只配置 tmux + 插件"
  echo "  git       - 只配置 git"
  exit 1
}

case "${1:-all}" in
all)
  setup_symlinks
  setup_tmux
  setup_git
  ;;
symlinks) setup_symlinks ;;
tmux) setup_tmux ;;
git) setup_git ;;
add) add_config "$2" ;; # ./cfg.sh add ~/.config/yazi
migrate) migrate_all ;; # ./cfg.sh migrate
*) usage ;;
esac
