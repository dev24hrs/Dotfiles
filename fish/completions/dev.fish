# Completions for dev — tmux session management
complete -f -c dev

# Subcommands
complete -f -c dev -n __fish_use_subcommand -a tmux -d "新建/进入左右 2-pane 的 tmux dev session"

# dev tmux [session-name]: 补全现有 tmux session 名; 只补到第 1 个参数为止
complete -f -c dev -n "__fish_seen_subcommand_from tmux; and test (count (commandline -opc)) -le 2" -a "(__fish_dev_session_names)" -d "tmux session"

function __fish_dev_session_names
    command -q tmux; or return
    tmux list-sessions -F '#{session_name}' 2>/dev/null
end
