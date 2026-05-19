#!/usr/bin/env bash
set -e

# ── 1. Xcode Command Line Tools ──────────────────────────────────────────────
echo "→ Checking Xcode Command Line Tools..."
if xcode-select -p &>/dev/null; then
  echo "  already installed, updating..."
  softwareupdate --all --install --force 2>/dev/null | grep -i "command line" || echo "  already up to date"
else
  echo "  not found, installing..."
  xcode-select --install
  # 等待安装完成（install 是异步的，需要轮询）
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
  echo "  installed successfully"
fi

# ── 2. Homebrew ───────────────────────────────────────────────────────────────
echo "→ Installing Homebrew..."
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

# ── 3. Git ────────────────────────────────────────────────────────────────────
echo "→ Checking git..."
if brew list git &>/dev/null; then
  echo "  brew git already installed, upgrading..."
  brew upgrade git 2>/dev/null || echo "  already up to date"
else
  echo "  installing git via brew..."
  brew install git
fi

echo "→ Configuring git..."
read -rp "  Git user name: " git_name
read -rp "  Git email: " git_email
git config --global user.name "$git_name"
git config --global user.email "$git_email"

echo "→ Generating SSH key..."
ssh-keygen -t ed25519 -C "$git_email" -f ~/.ssh/id_ed25519 -N ""
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

echo ""
echo "  ┌─────────────────────────────────────────────────────┐"
echo "  │  Copy the public key below and add it to GitHub:    │"
echo "  │  https://github.com/settings/ssh/new               │"
echo "  └─────────────────────────────────────────────────────┘"
cat ~/.ssh/id_ed25519.pub
echo ""
read -rp "  Press Enter after adding the key to GitHub..."

# verify
ssh -T git@github.com 2>&1 || true

# ── 4. Clone Dotfiles ─────────────────────────────────────────────────────────
echo "→ Cloning Dotfiles..."
git clone git@github.com:dev24hrs/Dotfiles.git ~/Documents/Dotfiles

# ── 5. Brewfile ───────────────────────────────────────────────────────────────
echo "→ Installing packages from Brewfile..."
brew bundle install --file=~/Documents/Dotfiles/Brewfile

# ── 6. Symlinks ───────────────────────────────────────────────────────────────
echo "→ Setting up detail config..."
cd ~/Documents/Dotfiles
chmod +x cfg.sh
./cfg.sh all

# ── 7. Fish shell ─────────────────────────────────────────────────────────────
echo "→ Setting fish as default shell..."
FISH_PATH=/opt/homebrew/bin/fish
grep -qF "$FISH_PATH" /etc/shells || echo "$FISH_PATH" | sudo tee -a /etc/shells
chsh -s "$FISH_PATH"

# ── 8. macOS defaults ─────────────────────────────────────────────────────────
echo "→ Applying macOS defaults..."
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

echo ""
echo "✓ Done! Restart terminal."
