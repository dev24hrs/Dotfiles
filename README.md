# [Mac] WorkFlow

> [!NOTE] This is a collection of configurations that includes all on my Mac.
>
> keywords: [git, homebrew, nerdfonts, fish, starship, neovim, tmux, golang, rust]

---

![](https://github.com/x3m4g63/Dotfiles/blob/main/img/nvim_tmux.png?raw=true)

---

## Enhance terminal

```bash
#  Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# Set a blazingly fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 1  # default 2，recommend 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# mac app id
osascript -e 'id of app "app name"'
# e.g
osascript -e 'id of app "Wezterm"'
```

> [!NOTE]
>
> 相关配置全部存放于Dotfiles目录, 通过`ln -s` 软链接到 `~/.config`,git版本管理

## Homebrew

install [homebrew](https://brew.sh/)

```bash
# 让当前 shell 能立即用 brew
eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
```

## Fish shell

- install [fish shell](https://fishshell.com/)

```bash
brew install fish
```

- set fish shell default

```bash
echo "$HOMEBREW_PREFIX/bin/fish" | sudo tee -a /etc/shells >/dev/null

# 切换默认shell为fish
chsh -s "$HOMEBREW_PREFIX/bin/fish"
```

- add homebrew to fish

```bash
# add to config.fish
# homebrew
eval (/opt/homebrew/bin/brew shellenv)

source ~/.config/fish/config.fish
```

## Git

- install [git](https://git-scm.com/install/mac)

```bash
brew install git

# 使 brew git 优先于系统 git
export PATH="$HOMEBREW_PREFIX/bin:$PATH"
```

- config git

refer to [git config](https://github.com/x3m4g63/Dotfiles/tree/main/git)

```bash
ln -s "git/.gitconfig" "$HOME/.gitconfig"
ln -s "git/.gitignore_global" "$HOME/.gitignore_global"
```

## Font

- english: recursive & fira

  ```bash
  brew install --cask font-recursive-mono-nerd-font
  brew install --cask font-fira-mono-nerd-font
  ```

- symbols

  ```bash
  brew install --cask font-symbols-only-nerd-font
  ```

- chinese simple : source-han-sans

  ```bash
  brew install --cask font-source-han-sans-vf
  ```

## Ghostty

- install [Ghostty](https://ghostty.org/docs)

```bash
brew install --cask ghostty
```

- config refer to [ghostty config](https://github.com/x3m4g63/Dotfiles/tree/main/ghostty)

## FzF

- install [fzf](https://junegunn.github.io/fzf/installation/)

```bash
brew install fzf
```

- config refer to [fzf config](https://github.com/x3m4g63/Dotfiles/blob/main/fish/config.fish)

```bash
# add to config.fish
# fzf
fzf --fish | source
set -gx FZF_DEFAULT_COMMAND 'fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"

set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border --preview 'bat --style=numbers --color=always --line-range :500 {}' --preview-window 'right,60%,border-left'"
set -gx FZF_CTRL_R_OPTS "--preview-window hidden"
```

## Neovim

- install [neovim](https://neovim.io/doc/install/)

```bash
brew install neovim
```

- config refer to [neovim config](https://github.com/x3m4g63/Dotfiles/tree/main/nvim)

## Tmux

- install [tmux](https://github.com/tmux/tmux/wiki)

```bash
brew install tmux
```

- config refer to [tmux config](https://github.com/x3m4g63/Dotfiles/tree/main/tmux)

## Zoxide

- install [zoxide](https://github.com/ajeetdsouza/zoxide)

```bash
brew install zoxide
```

- config with fish

```bash
# add to config.fish
zoxide init fish | source
```

## Eza

- install [eza](https://github.com/eza-community/eza)

```bash
brew install eza
```

- config with [abbrs.fish](https://github.com/x3m4g63/Dotfiles/blob/main/fish/abbrs.fish)

```bash
# add to abbrs.fish
alias ls='eza -a --icons --group-directories-first'
alias la='eza -la --icons --group-directories-first'
alias lt='eza -aT --icons --group-directories-first --git-ignore'
```

## Fd & RipGrep

- install [fd](https://github.com/sharkdp/fd)
- install [ripgrep](https://github.com/BurntSushi/ripgrep)

```bash
brew install fd
brew install ripgrep
```

## Starship

- install [starship](https://starship.rs/guide/)

```bash
brew install starship
```

- config refer to [starship config](https://github.com/x3m4g63/dotfiles/blob/main/starship.toml)

- with fish

```bash
starship init fish | source
```

## Bat

- install [bat](https://github.com/sharkdp/bat)

```bash
brew install bat
```

- config refer to [bat config](https://github.com/x3m4g63/Dotfiles/tree/main/bat)

```bash
# config
bat --generate-config-file
# add to ~/.config/bat/config
--paging=never
--theme="gruvbox-dark"
--style="numbers,changes,header,snip,rule"
```

- with fish

```bash
# add to config.fish
alias cat='bat'
```

## LazyGit

- install [lazygit](https://github.com/jesseduffield/lazygit)

```bash
brew install lazygit
```

- config refer to [config](https://github.com/x3m4g63/dotfiles/blob/main/lazygit/config.yml)

- with fish

```bash
alias lg='lazygit'
```

## Go-musicfox

- install [go-musicfox](https://github.com/go-musicfox/go-musicfox)

```bash
brew install anhoder/go-musicfox/go-musicfox
```

- config refer to [musicfox config](https://github.com/x3m4g63/Dotfiles/tree/main/go-musicfox)

- with fish

```bash
alias mu='musicfox'
```

## Yazi

- install [yazi](https://yazi-rs.github.io/docs/installation/)

```bash
brew install yazi ffmpeg-full sevenzip jq poppler fd ripgrep fzf zoxide resvg imagemagick-full font-symbols-only-nerd-font
brew link ffmpeg-full imagemagick-full -f --overwrite
```

- config refer to [yazi config](https://github.com/x3m4g63/Dotfiles/tree/main/yazi)

- with fish

```bash
# yazi
function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    command yazi $argv --cwd-file="$tmp"
    if read -z cwd <"$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
        builtin cd -- "$cwd"
    end
    command rm -f -- "$tmp"
end
```

## Worktrunk

config refer to [worktrunk](https://github.com/x3m4g63/Dotfiles/tree/main/worktrunk)

## Vimrc

Refer to [vimrc](https://github.com/x3m4g63/Dotfiles/blob/main/vimrc/vimrc)

## Rime 输入法

Refer to [rime 输入法](https://github.com/x3m4g63/Dotfiles/blob/main/Rime.md)

## cfg.sh

相关使用场景:

- 数据集维护在 config.map(单一数据源, 被 cfg.sh / setup.sh 共享)

```bash
# config.map — 格式: <dotfiles 内的相对路径>:<目标绝对路径>
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
  "hunk:$HOME/.config/hunk"
  "worktrunk:$HOME/.config/worktrunk"
)
```

- `./cfg.sh symlinks`: 之前手动维护 ~/.config & dotfiles,现在改成symlink方式

```bash
# 在Dotfiles目录执行 ./cfg.sh symlinks
# 自动在 ~/.config目录下创建相关链接,并链接到Dotfiles的对应配置目录/文件
# 同时备份之前手动管理的配置
```

- `./cfg.sh add`: 假如后续想安装某个/某些软件,在`Dotfiles`目录下配置之后

```bash
# 比如新安装了yazi,则在Dotfiles目录下执行
# 短路径
./cfg.sh add yazi
# 或者绝对路径
./cfg.sh add ~/Dotfiles/yazi

# 然后手动在 cfg.sh 的 setup_symlinks() 里补上对应的 make_link
# 最后 git 提交Dotfiles更新
```

## Brewfile

- 同步到 Brewfile 文件

```bash
brew bundle dump --file=~/Dotfiles/Brewfile --force --no-vscode
# --force 表示已存在则覆盖
# --no-vscode 表示跳过vscode相关
```

- 在新 mac 上安装 Brewfile 里的所有包

```bash
brew bundle install --file=~/Dotfiles/Brewfile
```

- 检查哪些包已安装、哪些还没装

```bash
brew bundle check --file=~/Dotfiles/Brewfile
```

## r2-upload-images.sh & cleanup-typora-images.sh

- 使用typora写md文档时,调用`wrangler`自动上传图片到cloudflare R2

- 手动cleanup执行清除typora的本地images副本

## Golang

- install [golang](https://golang.google.cn/doc/)

```bash
# brew install
brew install go
go version
brew upgrade go
```

- config golang

```bash
# set env
mkdir -p $HOME/Documents/Tools/GoPath/pkg
mkdir -p $HOME/Documents/Tools/GoPath/bin

go env -w GOPROXY=https://goproxy.cn,direct
go env -w GO111MODULE=on
go env -w GOPATH=$HOME/Documents/Tools/GoPath

# gofumpt
go install mvdan.cc/gofumpt@latest

# gopls
go install golang.org/x/tools/gopls@latest
```

- with fish

```bash
set -gx GOPATH $HOME/Documents/Tools/GoPath
fish_add_path $GOPATH/bin
```

### Books

- Go 语言圣经 <https://golang-china.github.io/gopl-zh/index.html>
- Go 语言设计与实现 <https://draveness.me/golang/>
- Go 语言高级编程 <https://chai2010.cn/advanced-go-programming-book/index.html>

## Setup

Refer to [set up](https://www.rust-lang.org/learn/get-started)

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

其他命令：

```bash
rustc --version
cargo --version
rustup update
```

- 官方文档中文 <https://rustwiki.org/>

- Rust 程序设计语言 <https://rustwiki.org/zh-CN/book/>

- Rust 程序设计语言 <https://doc.rust-lang.org/book/ch01-01-installation.html>

- Rust Cookbook 中文版 <https://rustwiki.org/zh-CN/rust-cookbook/>

### Awesome Rust

- awesome rust <https://github.com/rust-unofficial/awesome-rust>

- Rust 嵌入式 <https://github.com/rust-embedded/awesome-embedded-rust>

## Apps & Extensions

- [AlDente](https://apphousekitchen.com/) -- charge limiter app

- [Chrome](https://www.google.com/intl/zh-CN/chrome/) -- browser

- [appcleaner](https://freemacsoft.net/appcleaner/) -- app manager

- [snipaster](https://www.snipaste.com/) -- screenshot

- [vlc](https://www.videolan.org/vlc/) -- video player

- [Vimium](https://github.com/philc/vimium) -- Chrome extension for Vim

  ```bash
  # config Custom key
  unmap /
  map <c-/> enterFindMode
  # Custom search engines
  # so u can press o and enter g/bd/gh to search something
  bd: http://www.baidu.com/s?wd=%s+-csdn Baidu
  g: https://www.google.com/search?q=%s Google
  gh: https://github.com/search?q=%s GitHub
  ```

- [sublime text](https://www.sublimetext.com/) -- buy license from taobao

  ```bash
  {
  	"ignored_packages":
  	[
  		"Vintage",
  	],
  	"color_scheme": "ayu-light.sublime-color-scheme",
  	"theme": "ayu-light.sublime-theme",
  	"always_prompt_for_file_reload": true,
  	"font_size": 17,
  	"tab_size": 4,
  	"remember_open_files": false,
  	"hot_exit": false,
  	"update_check": false,
  	"font_face": "RecMonoCasual Nerd Font Mono",
  	"index_files": true,
  }
  ```

- [UBlacklit](https://chromewebstore.google.com/detail/ublacklist/pncfbmialoiaghdehhbnbhkkgmjanfhe) -- Chrome extension

  ```bash
  # ---------- 1. 域名规则（最可靠，建议保留） ----------
  # CSDN 主域及所有子域：blog.csdn.net、so.csdn.net、download.csdn.net …
  *://*.csdn.net/*

  # GitCode 主域及所有子域
  *://*.gitcode.com/*

  # GitCode 旧域名（可选）
  *://*.gitcode.net/*

  # ---------- 2. URL 关键词规则（兜底） ----------
  # 结果 URL 中包含关键词就屏蔽；可覆盖镜像站、跳转链接、带参数链接
  url *= "csdn.net"
  url *= "gitcode.com"
  url *= "gitcode.net"
  ```

- [沉浸式翻译](https://chromewebstore.google.com/detail/immersive-translate-ai-we/bpoadfkcbjbfhfodiogcnhhhpibjhbnh) -- Chrome extension

# LICENSE

This project is licensed under the MIT License.
