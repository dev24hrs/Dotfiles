# git
abbr -a gs 'git status'
abbr -a ga 'git add'
abbr -a gaa 'git add --all'
abbr -a gc 'git commit '
abbr -a gcm 'git commit -m'
abbr -a gca 'git commit --amend'

abbr -a gco 'git checkout'
abbr -a gsw 'git switch'
abbr -a gsc 'git switch -c'

abbr -a gd 'git diff'
abbr -a gf 'git fetch'
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

# homebrew
abbr -a bo 'brew outdated $(brew list --installed-on-request --formula) $(brew list --cask)'
abbr -a bc 'brew autoremove && brew cleanup --prune=all'
abbr -a bf 'brew bundle dump --file=$HOME/Documents/Dotfiles/Brewfile --force --no-vscode'

abbr -a bsl 'brew services list'
abbr -a bst 'brew services start'
abbr -a bsp 'brew services stop'
abbr -a bsr 'brew services restart'

# tmux
abbr -a ts 'tmux source-file ~/.config/tmux/tmux.conf'
abbr -a tl 'tmux ls'
abbr -a ta 'tmux attach -t'
abbr -a tn 'tmux new -s'
abbr -a tk 'tmux kill-session -t'

# golang
abbr -a gmi "go mod init"
abbr -a gmt "go mod tidy"
abbr -a gmc "go clean -modcache"
abbr -a gmv "go mod vendor"
abbr -a gmw "go mod why"
