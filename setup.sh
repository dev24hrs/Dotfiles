#!/usr/bin/env bash
# =============================================================================
# setup.sh — New Mac bootstrap for dev24hrs/Dotfiles
# 用法:
#   git clone https://github.com/dev24hrs/Dotfiles.git ~/Documents/Dotfiles
#   cd ~/Documents/Dotfiles && chmod +x setup.sh && ./setup.sh
# =============================================================================
set -Eeuo pipefail

# ── 颜色输出 ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
step() { echo -e "\n${BOLD}${CYAN}══ $* ${NC}"; }

# ── 路径变量 ─────────────────────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d_%H%M%S)"
if [[ "$(uname -m)" == "arm64" ]]; then
  HOMEBREW_PREFIX="/opt/homebrew"
else
  HOMEBREW_PREFIX="/usr/local"
fi

source "$DOTFILES_DIR/config.map"

# =============================================================================
# 工具函数
# =============================================================================

# 判断命令是否存在
has() { command -v "$1" &>/dev/null; }

# 创建 symlink，自动备份冲突的已有文件/目录
make_link() {
  local src="$DOTFILES_DIR/$1"
  local dst="$2"

  # 源不存在则跳过
  if [[ ! -e "$src" ]]; then
    warn "源不存在，跳过: $src"
    return
  fi

  # 目标已是指向同一源的 symlink，幂等跳过（用 readlink -f 比较规范化路径）
  if [[ -L "$dst" ]]; then
    local dst_real src_real
    dst_real="$(readlink -f "$dst" 2>/dev/null)" || true
    src_real="$(readlink -f "$src" 2>/dev/null)" || true
    if [[ -n "$dst_real" ]] && [[ -n "$src_real" ]] && [[ "$dst_real" == "$src_real" ]]; then
      info "已是正确链接，跳过: $dst"
      return
    fi
  fi

  # 目标存在（真实文件或不同 symlink），先备份
  if [[ -e "$dst" ]] || [[ -L "$dst" ]]; then
    mkdir -p "$BACKUP_DIR"
    local backup_path="$BACKUP_DIR/${1//\//_}"
    warn "备份冲突: $dst → $backup_path"
    mv "$dst" "$backup_path" || {
      error "备份失败: $dst"
      return 1
    }
  fi

  # 确保父目录存在
  mkdir -p "$(dirname "$dst")"

  ln -s "$src" "$dst" || {
    error "链接失败: $dst -> $src"
    return 1
  }
  success "链接: $dst → $src"
}

# =============================================================================
# STEP 0: 确认在 Dotfiles 目录下运行
# =============================================================================
step "0. 环境检查"

if [[ ! -f "$DOTFILES_DIR/Brewfile" ]]; then
  error "未在 Dotfiles 目录下找到 Brewfile，请先 clone 仓库再运行此脚本"
  error "  git clone https://github.com/dev24hrs/Dotfiles.git ~/Documents/Dotfiles"
  exit 1
fi

# 请求 sudo 并保持心跳，避免后续步骤中断
info "需要 sudo 权限安装部分组件..."
sudo -v
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null' EXIT INT TERM

success "Dotfiles 目录: $DOTFILES_DIR"

# =============================================================================
# STEP 1: Xcode Command Line Tools
# =============================================================================
step "1. Xcode Command Line Tools"

if xcode-select -p &>/dev/null; then
  success "Xcode CLT 已安装，跳过"
else
  info "安装 Xcode Command Line Tools（会弹出 GUI 提示框，请点击安装）..."
  xcode-select --install 2>/dev/null || true

  # 等待安装完成
  info "等待安装完成，可能需要几分钟（超时 15 分钟）..."
  timeout=180 elapsed=0
  until xcode-select -p &>/dev/null; do
    sleep 5
    elapsed=$((elapsed + 1))
    if [[ $elapsed -ge $timeout ]]; then
      error "Xcode CLT 安装超时，请手动安装后重新运行"
      exit 1
    fi
  done
  success "Xcode CLT 安装完成"
fi

# =============================================================================
# STEP 2: Homebrew
# =============================================================================
step "2. Homebrew"

if has brew; then
  success "Homebrew 已安装: $(brew --version | head -1)"
else
  info "安装 Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # 让当前 shell 能立即用 brew
  eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
  success "Homebrew 安装完成"
fi

# 确保 brew 在当前 shell PATH 中
eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"

# =============================================================================
# STEP 3: Git（brew 安装最新版）
# =============================================================================
step "3. Git"

if has git && [[ "$(git --version)" != *"Apple"* ]]; then
  success "Git 已由 Homebrew 管理: $(git --version)"
else
  info "通过 Homebrew 安装最新 Git..."
  brew install git
  # 使 brew git 优先于系统 git
  export PATH="$HOMEBREW_PREFIX/bin:$PATH"
  success "Git 安装完成: $(git --version)"
fi

# =============================================================================
# STEP 4: Git 配置 symlink（git 装好后立即链接，brew bundle 中 git 命令会用到）
# =============================================================================
step "4. Git 配置 Symlink"

make_link "git/.gitconfig" "$HOME/.gitconfig"
make_link "git/.gitignore_global" "$HOME/.gitignore_global"

# 提示：.gitconfig 里硬编码了代理 ，按需取消
if grep -q "proxy = 127.0.0.1" "$DOTFILES_DIR/git/.gitconfig" 2>/dev/null; then
  warn ".gitconfig 包含代理设置 (127.0.0.1:7897)，若当前环境无代理请手动注释:"
  warn "  git config --global --unset http.proxy"
  warn "  git config --global --unset https.proxy"
fi

# =============================================================================
# STEP 5: brew bundle 安装所有软件
# =============================================================================
step "5. brew bundle（安装 Brewfile 中所有包）"

info "开始安装，请耐心等待..."

# --no-lock 避免写 Brewfile.lock.json 到仓库目录
if brew bundle install \
  --file="$DOTFILES_DIR/Brewfile" \
  --no-lock \
  --verbose; then
  success "brew bundle 完成"
else
  warn "部分包安装失败，已跳过继续（见上方输出）"
fi

# =============================================================================
# STEP 6: 将 fish 加入受信 shell 列表，并设为默认 shell
# =============================================================================
step "6. Fish Shell 设为默认"

FISH_PATH="$HOMEBREW_PREFIX/bin/fish"

if ! has fish; then
  error "fish 未安装，请检查 Brewfile"
  exit 1
fi

# 加入 /etc/shells（需要 sudo）
if ! grep -qxF "$FISH_PATH" /etc/shells; then
  info "将 $FISH_PATH 添加到 /etc/shells..."
  echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
  success "已添加到 /etc/shells"
else
  success "$FISH_PATH 已在 /etc/shells"
fi

# 切换默认 shell
if [[ "$SHELL" == "$FISH_PATH" ]]; then
  success "默认 shell 已是 fish，跳过"
else
  info "切换默认 shell 为 fish（需要输入当前用户密码）..."
  chsh -s "$FISH_PATH"
  success "默认 shell 已切换为 fish"
fi

# =============================================================================
# STEP 7: 创建所有 dotfiles symlink
# =============================================================================
step "7. 创建 ~/.config Symlinks"

mkdir -p "$HOME/.config"

for entry in "${CONFIG_MAP[@]}"; do
  src="${entry%%:*}" # 冒号前：dotfiles 相对路径
  dst="${entry##*:}" # 冒号后：目标绝对路径

  make_link "$src" "$dst"
done

success "Symlinks 创建完成"

# =============================================================================
# STEP 8: Go 环境配置（go-musicfox 等工具依赖）
# =============================================================================
step "8. Go 环境变量配置"

if has go; then
  GOPATH="$HOME/Documents/Tools/GoPath"
  mkdir -p "$GOPATH/pkg" "$GOPATH/bin"

  go env -w GOPROXY=https://goproxy.cn,direct || true
  go env -w GO111MODULE=on || true
  go env -w GOPATH="$GOPATH" || true

  success "GOPATH 设为: $GOPATH"
  info "GOPROXY 已设为 goproxy.cn（国内加速）"
else
  warn "go 未找到，跳过 Go 环境配置"
fi

# =============================================================================
# STEP 9: macOS 键盘加速（按 README 建议）
# =============================================================================
step "9. macOS 键盘重复速率调整（可选）"

read -r -p "  是否应用 macOS 键盘加速设置? (建议 yes) [y/N] " apply_kbd
if [[ "$apply_kbd" =~ ^[Yy]$ ]]; then
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
  defaults write NSGlobalDomain KeyRepeat -int 1
  defaults write NSGlobalDomain InitialKeyRepeat -int 10
  success "键盘加速设置已应用（重启后生效）"
else
  info "跳过键盘设置"
fi

# =============================================================================
# STEP 10: Rust（可选，仅在未安装时询问）
# =============================================================================
step "10. Rust 安装（可选）"

if has rustc; then
  success "Rust 已安装: $(rustc --version)"
else
  read -r -p "  是否安装 Rust (rustup)? [y/N] " install_rust
  if [[ "$install_rust" =~ ^[Yy]$ ]]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # 让当前 shell 能用 cargo
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
    success "Rust 安装完成: $(rustc --version)"
  else
    info "跳过 Rust 安装"
  fi
fi

# =============================================================================
# STEP 11: tmux TPM 及插件安装
# =============================================================================
step "11. tmux 插件（TPM）"

TPM_DIR="$HOME/.config/tmux/plugins/tpm"
# 注意：~/.config/tmux 已 symlink 到 ~/Documents/Dotfiles/tmux
# 所以 TPM 实际安装到 Dotfiles/tmux/plugins/，由 .gitignore 中的 tmux/plugins/ 忽略

if [[ -d "$TPM_DIR" ]]; then
  success "TPM 已存在，跳过 clone"
else
  info "克隆 TPM..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  success "TPM clone 完成"
fi

# 用 TPM 的 headless 安装脚本批量安装插件
# 等价于在 tmux 里按 prefix + I
info "安装 tmux 插件（tmux-sensible）..."
TMUX_PLUGIN_MANAGER_PATH="$HOME/.config/tmux/plugins" \
  bash "$TPM_DIR/scripts/install_plugins.sh" 2>&1 | grep -v "^$" || true
success "tmux 插件安装完成"

# =============================================================================
# STEP 12: yazi 插件安装
# =============================================================================
step "12. yazi 插件（ya pack）"

if ! has ya; then
  warn "ya 命令未找到，跳过 yazi 插件安装（yazi 是否已正确安装？）"
else
  info "安装 yazi 插件（full-border, git, smart-enter, smart-paste, mediainfo, gruvbox-material）..."
  # package.toml 已通过 symlink 链接到 ~/.config/yazi/package.toml
  # ya pack -i 会读取该文件并安装所有 deps
  if ya pack -i; then
    success "yazi 插件安装完成"
  else
    warn "yazi 部分插件安装失败（见上方输出）"
  fi
fi

# =============================================================================
# 完成
# =============================================================================
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║           🎉 Setup 完成！                        ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# 汇总提示
if [[ -d "$BACKUP_DIR" ]]; then
  warn "冲突备份已保存至: $BACKUP_DIR"
fi

echo -e "${CYAN}后续手动步骤:${NC}"
echo "  1. 字体安装（手动，避免 brew 安装全系列字体）:"
echo "       Nerd Fonts: https://www.nerdfonts.com/font-downloads"
echo "       思源黑体 SC: https://github.com/adobe-fonts/source-han-sans/releases"
echo "       ⚠️  fish/starship/ghostty/wezterm 等配置均依赖 Nerd Fonts，请先安装字体再重启终端"
echo "  2. 重启终端（或新开一个 session）以使 fish 生效"
echo "  3. 在新终端中验证: echo \$SHELL  # 应显示 $FISH_PATH"
echo "  4. SSH key 配置:"
echo "       ssh-keygen -t ed25519 -C 'your_email@example.com'"
echo "       pbcopy < ~/.ssh/id_ed25519.pub  # 复制到 GitHub → Settings → SSH Keys"
echo "  5. 若无代理，取消 ~/.gitconfig 中的 proxy 设置:"
echo "       git config --global --unset http.proxy"
echo "       git config --global --unset https.proxy"
echo "  6. 按需创建 API key 配置文件（已在 .gitignore 中，不会提交）:"
echo "       touch ~/.config/fish/conf.d/apiKey.fish"
echo "       # 在其中写入: set -gx ANTHROPIC_API_KEY 'sk-...'"
echo ""
