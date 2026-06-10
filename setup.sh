#!/usr/bin/env bash
set -euo pipefail

# ── helpers ──────────────────────────────────────────────────────────────────
ok() { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }
err() { echo "  ✗ $1" >&2; }

DOTFILES_DIR="$HOME/Documents/Dotfiles"

# ── 1. Xcode Command Line Tools ──────────────────────────────────────────────
echo "→ Checking Xcode Command Line Tools..."
if xcode-select -p &>/dev/null; then
  ok "already installed"
else
  echo "  not found, installing..."
  xcode-select --install
  # 等待安装完成 (install 是异步的,需要轮询)
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
  ok "installed successfully"
fi

# ── 2. Homebrew ───────────────────────────────────────────────────────────────
echo "→ Installing Homebrew..."
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
ok "brew ready: $(brew --version | head -1)"

# ── 3. Git (引导用,Brewfile 里可能也有) ───────────────────────────────────────
echo "→ Checking git..."
if brew list git &>/dev/null; then
  ok "brew git already installed"
else
  echo "  installing git via brew..."
  brew install git
fi

# ── 4. 收集身份信息 (SSH key 与后续 git config 都需要) ─────────────────────────
echo "→ Collecting identity..."
read -rp "  Git user name: " git_name
read -rp "  Git email: " git_email

# ── 5. SSH key ────────────────────────────────────────────────────────────────
SSH_KEY="$HOME/.ssh/id_ed25519"
echo "→ Setting up SSH key..."
if [ -f "$SSH_KEY" ]; then
  ok "ssh key already exists: $SSH_KEY"
else
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -C "$git_email" -f "$SSH_KEY" -N ""
  ok "ssh key generated"
fi
eval "$(ssh-agent -s)" >/dev/null
ssh-add "$SSH_KEY" 2>/dev/null || true

echo ""
echo "  ┌─────────────────────────────────────────────────────┐"
echo "  │  Copy the public key below and add it to GitHub:    │"
echo "  │  https://github.com/settings/ssh/new                │"
echo "  └─────────────────────────────────────────────────────┘"
cat "${SSH_KEY}.pub"
echo ""
read -rp "  Press Enter after adding the key to GitHub..."

# verify (失败不退出,首次连接会有 host key 提示)
ssh -T -o StrictHostKeyChecking=accept-new git@github.com 2>&1 || true

# ── 6. Clone Dotfiles ─────────────────────────────────────────────────────────
echo "→ Cloning Dotfiles..."
if [ -d "$DOTFILES_DIR/.git" ]; then
  ok "Dotfiles already cloned at $DOTFILES_DIR"
else
  git clone git@github.com:dev24hrs/Dotfiles.git "$DOTFILES_DIR"
  ok "Dotfiles cloned"
fi

# ── 7. Brewfile ───────────────────────────────────────────────────────────────
echo "→ Installing packages from Brewfile..."
brew bundle install --file="$DOTFILES_DIR/Brewfile"

# ── 8. Symlinks (必须在 git config 之前,否则 ~/.gitconfig 会被备份覆盖) ────────
echo "→ Setting up symlinks..."
cd "$DOTFILES_DIR"
chmod +x cfg.sh
./cfg.sh symlinks

# ── 9. Git 配置 (写穿透到符号链接,即 Dotfiles 里的 .gitconfig) ────────────────
echo "→ Configuring git identity..."
git config --global user.name "$git_name"
git config --global user.email "$git_email"
git config --global core.excludesfile "$HOME/.gitignore_global"
ok "git identity & global gitignore set"

# ── 10. Fish shell ────────────────────────────────────────────────────────────
echo "→ Setting fish as default shell..."
FISH_PATH=/opt/homebrew/bin/fish
if ! grep -qF "$FISH_PATH" /etc/shells; then
  echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
fi
if [ "${SHELL:-}" != "$FISH_PATH" ]; then
  chsh -s "$FISH_PATH"
  ok "default shell set to fish"
else
  ok "fish already default shell"
fi

# ── 11. tmux + TPM ────────────────────────────────────────────────────────────
echo "→ Configuring tmux..."
TPM_DIR="$DOTFILES_DIR/tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  ok "TPM cloned"
else
  ok "TPM already installed"
fi

# 安装插件 (headless)
tmux new-session -d -s cfg_setup 2>/dev/null || true
TMUX_PLUGIN_MANAGER_PATH="$DOTFILES_DIR/tmux/plugins" \
  "$TPM_DIR/bin/install_plugins" || warn "tmux plugin install reported errors"
tmux kill-session -t cfg_setup 2>/dev/null || true
ok "tmux plugins installed"

# ── 12. macOS defaults ────────────────────────────────────────────────────────
echo "→ Applying macOS defaults..."
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10
ok "macOS defaults written (logout/restart required for full effect)"

echo ""
echo "✓ Done! Restart terminal (and log out once for keyboard defaults to fully apply)."
