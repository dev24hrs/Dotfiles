# [Mac] WorkFlow

> [!NOTE] This is a collection of configurations that includes all on my Mac.
>
> keywords: [git, homebrew, nerdfonts, fish, starship, neovim, tmux, golang, rust]

---

![](https://github.com/dev24hrs/Dotfiles/blob/main/img/nvim_tmux.png?raw=true)

---

## setup.sh & cfg.sh

### setup.sh

新mac: 无任何环境配置

```bash
git clone https://github.com/dev24hrs/Dotfiles.git ~/Documents/Dotfiles
cd ~/Documents/Dotfiles && chmod +x setup.sh && ./setup.sh
# setup.sh 脚本会执行dotfiles的所有配置
```

### cfg.sh

相关使用场景:

- `./cfg.sh symlinks`: 当前mac环境,之前手动配置 `~/.config`,也手动维护`dotfiles`目录,现在改成symlink方式

```bash
# 在Dotfiles目录执行 ./cfg.sh symlinks
# 自动在 ~/.config目录下创建相关链接,并链接到Dotfiles的对应配置目录
# 同时备份之前手动管理的配置
```

- `./cfg.sh add `: 假如后续想安装某个某些软件,需要配置 `~/.config` / `~`目录

```bash
# 比如新安装了yazi,则在Dotfiles目录下执行
./cfg.sh add ~/.config/yazi
# 或者
./cfg.sh add ~/.hammerspoon

# 然后手动在 cfg.sh 的 setup_symlinks() 里补上对应的 make_link
# 最后 git 提交Dotfiles更新
```

- `./cfg migrate`: 当前mac环境,之前只手动配置`~/.config`,无`dotfiles`

```bash
mkdir -p ~/Dotfiles && cd ~/Dotfiles

# 把config 已有配置都迁移进 Dotfiles
./cfg.sh migrate

# 检查结果
ls -la ~/.config/fish   # 应该显示 -> ~/Dotfiles/fish

# 3. 提交
git add .
git commit -m "chore: migrate existing configs to Dotfiles"
git push
```

## Brewfile

-   导出当前 mac 已安装的所有包

```bash
brew bundle dump --file=~/Dotfiles/Brewfile --force
# --force 表示已存在则覆盖
```

-   在新 mac 上安装 Brewfile 里的所有包

```bash
brew bundle install --file=~/Dotfiles/Brewfile
```

-   检查哪些包已安装、哪些还没装

```bash
brew bundle check --file=~/Dotfiles/Brewfile
```

-   清理本机有但 Brewfile 里没有的包（同步删除）

```bash
brew bundle cleanup --file=~/Dotfiles/Brewfile
# 加 --force 才会真正删除，不加只是预览
brew bundle cleanup --file=~/Dotfiles/Brewfile --force
```

-   装了新包之后同步到 Brewfile

```bash
# 重新导出
brew bundle dump --file=~/Dotfiles/Brewfile --force
```

-   Fish脚本

~~~bash

~~~

## Enhance terminal

> [!NOTE]
>
> 已存在于 [setup.sh](https://github.com/dev24hrs/Dotfiles/blob/main/setup.sh) 自动配置

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

## Git Config

refer to [git config](https://github.com/dev24hrs/Dotfiles/tree/main/git)

## Homebrew

Use pkg to install [homebrew](https://github.com/Homebrew/brew/releases/), but need to config `config.fish`

```bash
# add to config.fish
# homebrew
eval (/opt/homebrew/bin/brew shellenv)

# set ustc mirrors
# export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
# export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
# export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
# then
source ~/.config/fish/config.fish

brew update
# if unistall
# then brew autoremove
# brew cleanup
# brew cleanup --prune=all
```

## Font

### brew install

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

### manual install (Recommend)

> [!NOTE]
>
> The brew method installs many unnecessary fonts. For example, when installing Source Han Sans,
> brew will automatically install Japanese, Korean, and Traditional Chinese fonts, but I only need Simplified Chinese.

- english

  ```bash
  ## recursive & fira
  https://www.nerdfonts.com/font-downloads
  ```

- chinese simple

  ```bash
  ## chinese simple otf
  https://github.com/adobe-fonts/source-han-sans/releases
  ```

## Fish Shell

refer to [fish config](https://github.com/dev24hrs/Dotfiles/tree/main/fish)

## Cli Tools

### Starship

refer to [starship config](https://github.com/dev24hrs/dotfiles/blob/main/starship.toml)

- install [starship](https://starship.rs/guide/)

```bash
brew install starship
```

- with fish

```bash
starship init fish | source

# config
# use preset & restart terminal starship preset nerd-font-symbols -o ~/.config/starship/starship.toml
# or can refer to github dotfiles
```

### Bat

- install [bat](https://github.com/sharkdp/bat)

```bash
brew install bat
```

- config

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

### Fzf

- install [fzf](https://github.com/junegunn/fzf)

```bash
brew install fzf
```

- with fish

```bash
# add to config.fish
# FZF
fzf --fish | source
set -gx FZF_DEFAULT_COMMAND 'fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border --preview 'bat --style=numbers --color=always --line-range :500 {}' --preview-window 'right,60%,border-left'"
set -gx FZF_CTRL_R_OPTS "--preview-window hidden"
```

### Zoxide

- install [zoxide](https://github.com/ajeetdsouza/zoxide)

```bash
brew install zoxide
```

- with fish

```bash
zoxide init fish | source
```

### Delta

- install [delta](https://github.com/dandavison/delta)

```bash
brew install git-delta
```

### Eza

- install [eza](https://github.com/eza-community/eza)

  ```bash
  brew install eza
  ```

- with fish

  ```bash
  alias ls='eza -a --icons --group-directories-first'
  alias la='eza -la --icons --group-directories-first'
  alias lt='eza -aT --icons --group-directories-first --git-ignore'
  ```

### Fd & RipGrep

- install [fd](https://github.com/sharkdp/fd)
- install [ripgrep](https://github.com/BurntSushi/ripgrep)

```bash
brew install fd
brew install ripgrep
```

### LazyGit

refer to [config](https://github.com/dev24hrs/dotfiles/blob/main/lazygit/config.yml) or [default config](https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md)

- install [lazygit](https://github.com/jesseduffield/lazygit)

```bash
brew install lazygit
```

- with fish

```bash
alias lg='lazygit'
```

### Cheat.sh

- install [cheat.sh](https://github.com/chubin/cheat.sh)

```bash
# add to config.fish
function ch --description 'curl cheat.sh'
    curl cheat.sh/$argv[1]
end

# use
ch go chan
```

### Go-musicbox

- install [go-musicfox](https://github.com/go-musicfox/go-musicfox)

```bash
brew install anhoder/go-musicfox/go-musicfox
```

- with fish

```bash
alias mu='musicfox'
```

## WezTerm

refer to [wezterm config](https://github.com/dev24hrs/dotfiles/tree/main/wezterm)

- install [wezterm](https://wezterm.org/install/macos.html#homebrew)

```bash
brew install --cask wezterm@nightly
```

## Tmux

config refer to [tmux dotfiles](https://github.com/dev24hrs/dotfiles/tree/main/tmux)

## Neovim

config refer to [nvim dotfiles](https://github.com/dev24hrs/dotfiles/tree/main/nvim)

## Vimrc

Refer to [vimrc](https://github.com/dev24hrs/Dotfiles/blob/main/vimrc/vimrc)

## Rime 输入法

Refer to [rime 输入法](https://github.com/dev24hrs/Dotfiles/blob/main/Rime.md)

## Golang

- install

```bash
# brew install
brew install go
go version
brew upgrade go

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

## Rust

### Setup

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

## Apps

- [AlDente](https://apphousekitchen.com/) -- charge limiter app

- [lemon](https://lemon.qq.com/) -- mac clean app

- [Chrome](https://www.google.com/intl/zh-CN/chrome/) -- browser

- [appcleaner](https://freemacsoft.net/appcleaner/) -- app manager

- [snipaster](https://www.snipaste.com/) -- screenshot

- [vlc](https://www.videolan.org/vlc/) -- video player

- [Vimium](https://github.com/philc/vimium) -- Chrome & Arc extension for Vim

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
   "font_size": 16,
   "remember_open_files": true,
   "update_check": false,
   "font_face": "RecMonoCasual Nerd Font",
  }
  ```

- [PicGo](https://picgo.github.io/PicGo-Doc/zh/guide/) -- upload images to GitHub

  > if u forget your GitHub tokens, u cant find it in the blew file `data.json`

  ```json
  // the data.json saved all the uploaded imgs info
  // this is vscode settings
  "picgo.dataPath": "$home/Library/Application Support/picgo/data.json",
  ```

  If use typora & picgo app, when u pasted images in typora,it will cached images in the path`$home/Library/Application\ Support/typora-user-images`,so u need clean it.

# LICENSE

This project is licensed under the MIT License.
