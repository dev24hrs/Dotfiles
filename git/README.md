# Git Config

refer to [git config](https://github.com/dev24hrs/Dotfiles/tree/main/git)

1. git init
   refer to [new ssh key](https://docs.github.com/zh/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

```bash
# ssh-key
brew install openssh
ssh-keygen -t ed25519 -C "your_email@example.com"

touch ~/.ssh/config

# add
Host github.com
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_ed25519

ssh-add ~/.ssh/id_ed25519

pbcopy < ~/.ssh/id_ed25519.pub
# then add to your github settings->ssh key
```

2. git config
   `~/.gitconfig` 或 `~/.config/git/config`

<details>
  <summary>git config</summary>

```bash
[user]
  name = xxx
  email = xxx@gmail.com
[core]
  editor = nvim
  pager = delta
  # 自动转换换行符 (Windows 设为 true, macOS/Linux 设为 input)
  autocrlf = input
  # 忽略文件权限变化（避免因为 chmod 导致整片文件变红)
  filemode = false
  # 开启文件系统监视器，极大提升在大型仓库中执行 git status 的速度
  fsmonitor = true
  # 忽略全局的各种系统生成文件 (需自行创建该文件)
  excludesfile = ~/.gitignore_global
  # 确保分页器使用系统自带的 less，并支持颜色显示
  pager = less -RFX

[init]
  # 默认初始分支名为 main
  defaultBranch = main

[branch]
  # 分支排序：按最近提交时间排序，最常修改的分支排在前面
  sort = -committerdate

[color]
  ui = auto
[color "diff"]
  meta = yellow bold
  frag = magenta bold
  old = red bold
  new = green bold
[color "status"]
  added = yellow
  changed = green
  untracked = cyan

[diff]
  # 启用自动换行检测，避免在对比时看到一堆空白字符的变动
  ignoreBlankLines = true
  ignoreSpaceAtEol = true
  # 使用更聪明的直方图算法生成 diff，对比结果更符合人类逻辑
  algorithm = histogram
  # 开启重命名检测的高级模式（复制和重命名）
  renames = copies
  # 让 delta 自动对搬移的代码块着色，而不是标为删除+新增
  colorMoved = default
  # zebra 模式会用不同的颜色标注掉迁出和迁入的代码块，而不是简单的红绿
  colorMoved = zebra
  # 显示更精细的差异（按字对比而非仅按行）
  wordDiff = color
  # 针对子模块显示更详细的差异
  submodule = log
  # 缩进启发式：让 Diff 块尽量在空行处分割，保持代码块完整性。
  indentHeuristic = true

[merge]
  conflictstyle = zdiff3

[fetch]
  # 拉取时自动清理远程已删除的分支（保持本地分支列表干净）
  prune = true
  # 自动拉取远程的 tag
  tags = true

[pull]
  # 拉取代码时默认使用 rebase 而不是 merge，保持提交历史呈线性
  rebase = true

[push]
  # 推送新分支时自动建立远程关联，无需再输入 --set-upstream
  autoSetupRemote = true
  # 仅推送当前分支到同名远程分支
  default = current
  # 极其重要的安全设置：如果是强制推送，检查本地是否包含了远程最新的提交，防止覆盖同事代码
  useForceIfIncludes = true

[rebase]
  # rebase 前自动暂存未提交的工作，结束后自动恢复（非常实用！）
  autoStash = true
  # 自动将 fixup! 和 squash! 的提交在 rebase -i 时合并
  autoSquash = true

```

</details>

3. gitignore

```bash
# macOS
.DS_Store

# 常见的依赖目录
node_modules/
.venv/
venv/

# IDE 相关
.vscode/
.idea/

# Go 相关的临时文件
*.test
*.out

# Python 相关的临时文件
__pycache__

# Java 相关的临时文件
*.class

# Web 相关的临时文件
*.lock

# React 相关的临时文件
*.js.map

# 其他敏感或环境隔离文件
*.log
.env.local
.env.*.local
```

4. git abbr

```bash
# gs gb gl rewrite by git.fish
abbr -a ga 'git add'
abbr -a gaa 'git add --all'
abbr -a gcm 'git commit -m'
abbr -a gca 'git commit --amend'

abbr -a gco 'git checkout'
abbr -a gsw 'git switch'
abbr -a gsc 'git switch -c'

abbr -a gd 'git diff'
abbr -a gf 'git fetch'
abbr -a gl 'git pull'
abbr -a gp 'git push'
abbr -a gpf 'git push --force-with-lease' # 比 --force 更安全

abbr -a gst 'git stash'
abbr -a gsp 'git stash pop'
abbr -a gsl 'git stash list'

abbr -a gr 'git rebase'
abbr -a gra 'git rebase --abort'
abbr -a grc 'git rebase --continue'
abbr -a gri 'git rebase -i'
abbr -a grh 'git reset --hard'
abbr -a grs 'git reset --soft'
```
