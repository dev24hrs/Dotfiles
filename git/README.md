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
