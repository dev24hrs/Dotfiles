# Fish Shell

## 安装

```bash
brew install fish
```

## fish 作为默认shell

```bash
# Fish 路径写入信任列表
echo $(which fish) | sudo tee -a /etc/shells

# 切换默认 Shell
chsh -s $(which fish)
```

## 文件结构

`~/.config/fish/`

```bash
# 将 apiKey.fish 加入.gitignore
fish/conf.d/apiKey.fish
# 同时新增 apiKey.fish.example文件
```

```bash
├── completions 		          ## functions补全提示
│ ├── proxy.fish
│ └── tool.fish
├── conf.d
│ ├── envPath.fish 		        ## env path相关
│ ├── apiKey.fish.example 		## deepseek api等
│ └── lastPwd.fish 		        ## 上一次目录
├── functions
│ ├── proxy.fish 		          ## 开启/关闭/查看git代理
│ └── tool.fish 		          ## 自定义工具
├── README.md
├── abbrs.fish 			          ## abbrs相关
├── config.fish			          ## 主配置文件
└── fish_variables
```

在 Fish Shell 中，**completions & conf.d & functions & config.fish** 共同构成了一个高效、模块化且支持“延迟加载”的配置系统。

以上配置文件结构尽可能遵循 `模块化`和`延迟加载`

### completions

专门负责**命令补全提示**的逻辑

- 当你输入自定义命令按下 `Tab` 键时，Fish 会到这里寻找对应命令的补全定义
- 文件名必须与命令名一致。例如 `proxy` 的补全定义放在 `completions/proxy.fish`

### conf.d

存放**环境变量**和**启动脚本**

- Fish 在启动时，会**自动遍历并执行**该目录下所有的 `.fish` 文件
- **在执行 `config.fish` 之前加载**

### functions

存放**自定义命令（函数）**

- 实现**延迟加载（Autoloading）**。只有当你真正输入命令并按下回车时，Fish 才会去这个目录下寻找同名的 `.fish` 文件并加载
- 文件名必须与函数名完全一致。例如，函数名为 `proxy`，文件名必须是 `proxy.fish`

### config.fish

**主配置文件**

- 存放基础设置 , 如隐藏启动欢迎语 `set -g fish_greeting ""`
- abbr & aliases
  - `abbr`相关的代码被单独抽离成文件`abbrs.fish` , 然后在config.fish中 source 引用, 防止后期过多的abbr
- 配置, 如 Starship & homebrew & zoxide & fzf 等初始化
- 不单独归类的设置, 如git.fish.
  - 因为如果把git.fish存放在functions目录下, 对应的N个相关函数需要新建N个文件

## 设置

### config.fish

```bash
set -g fish_greeting ""
set -gx TERM xterm-256color
set -gx EDITOR nvim

# homebrew
eval (/opt/homebrew/bin/brew shellenv)

# aliases
alias lg='lazygit'
alias mu='musicfox'

# eza
alias ls='eza -a --icons --group-directories-first'
alias la='eza -la --icons --group-directories-first'
alias lt='eza -aT --icons --group-directories-first --git-ignore'

# source
if test -f $HOME/.config/fish/abbrs.fish
    source $HOME/.config/fish/abbrs.fish
end
if test -f $HOME/.config/fish/git.fish
    source $HOME/.config/fish/git.fish
end

# fzf
fzf --fish | source
set -gx FZF_DEFAULT_COMMAND 'fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border --preview 'bat --style=numbers --color=always --line-range :500 {}' --preview-window 'right,60%,border-left'"
set -gx FZF_CTRL_R_OPTS "--preview-window hidden"

# starship
starship init fish | source
# zoxide
zoxide init fish | source
```

### completions

补全效果:

```bash
➜ tool ds
ch  (查询 cheat.sh 备忘录)  ds  (清除当前目录下的 .DS_Store 文件)  nh  (使用 nohup 后台运行命令)
```

### functions

自定义命令:

```bash
➜ proxy on
off  (关闭 Git 全局代理配置)  on  (开启 Git 代理)  show  (显示 Git 代理信息)
```

### conf.d

- envPath.fish

```bash
# 自定义 XDG_CONFIG_HOME
set -gx XDG_CONFIG_HOME "$HOME/.config"

# 自定义 STARSHIP_CONFIG
set -gx STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"
```
