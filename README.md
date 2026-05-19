# [Mac] WorkFlow

> [!NOTE] This is a collection of configurations that includes all on my Mac.
>
> keywords: [git, homebrew, nerdfonts, fish, starship, neovim, tmux, golang, rust]

---

![](https://github.com/dev24hrs/Dotfiles/blob/main/img/nvim_tmux.png?raw=true)

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

## Git Config

refer to [git config](https://github.com/dev24hrs/Dotfiles/tree/main/git)

## Homebrew

Use pkg to install [homebrew](https://github.com/Homebrew/brew/releases/), but need to config `~/.zshrc` or `config.fish`

```bash
# add to config.fish
# homebrew
eval (/opt/homebrew/bin/brew shellenv)

# add to ~/.zshrc
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

# set ustc mirrors
# export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
# export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
# export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
# then
source ~/.zshrc

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
# use preset & restart terminal starship preset nerd-font-symbols -o ~/.config/starship.toml
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

~~### Lsd~~

- install [lsd](https://github.com/lsd-rs/lsd)

```bash
brew install lsd
```

- with fish

```bash
# lsd
alias ls='lsd'
alias la='lsd -la'
alias lt='lsd --tree'
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

### Btop

- install [btop](https://github.com/aristocratos/btop)

```bash
brew install btop
```

- config

```bash
# config path is : $HOME/.config/btop/btop.conf
# themes path is : $HOME/.config/btop/themes/
# add https://github.com/aristocratos/btop/blob/main/themes/gruvbox_material_dark.theme to theme path

# use bt and the press m to option config to set theme as gruvbox_material_dark
```

- with fish

```bash
alias bt='btop'
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

## Rime

Refer to [rime 输入法](https://github.com/dev24hrs/Dotfiles/blob/main/Rime.md)

## setup.sh

```bash
新mac安装环境:
git clone https://github.com/dev24hrs/Dotfiles.git ~/Documents/Dotfiles
cd ~/Documents/Dotfiles && chmod +x setup.sh && ./setup.sh

# LICENSE

This project is licensed under the MIT License.
```
