# basic
set -g fish_greeting ""
set -gx TERM xterm-256color
set -gx EDITOR nvim
# 禁用less历史记录
set -gx LESSHISTFILE -

# homebrew
eval (/opt/homebrew/bin/brew shellenv)

# alias
alias lg='lazygit'
alias mu='musicfox'

alias ls='eza -a --icons --group-directories-first'
alias la='eza -la --icons --group-directories-first'
alias lt='eza -aT --icons --group-directories-first --git-ignore'

# fzf
fzf --fish | source
set -gx FZF_DEFAULT_COMMAND 'fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"

set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border --preview 'bat --style=numbers --color=always --line-range :500 {}' --preview-window 'right,60%,border-left'"
set -gx FZF_CTRL_R_OPTS "--preview-window hidden"

# source files
if test -f $HOME/.config/fish/abbrs.fish
    source $HOME/.config/fish/abbrs.fish
end
if test -f $HOME/.config/fish/git.fish
    source $HOME/.config/fish/git.fish
end

# yazi
function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    command yazi $argv --cwd-file="$tmp"
    if read -z cwd <"$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
        builtin cd -- "$cwd"
    end
    command rm -f -- "$tmp"
end

# starship
starship init fish | source
# zoxide
zoxide init fish | source

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :

# Added by LM Studio CLI (lms)
set -gx PATH $PATH $HOME/.lmstudio/bin
# End of LM Studio CLI section
