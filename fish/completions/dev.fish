# Completions for dev — git worktree management (current repo only)
complete -f -c dev

# Top-level subcommands
complete -f -c dev -n __fish_use_subcommand -a worktree -d "Manage git worktrees"
complete -f -c dev -n __fish_use_subcommand -a layout -d "Create tmux session with standard project layout"

# After 'layout', complete with directory paths
complete -c dev -n "__fish_seen_subcommand_from layout" -a "(__fish_complete_directories)" -d "project path"

# After 'worktree', complete with worktree subcommands
complete -f -c dev -n "__fish_seen_subcommand_from worktree" -a new -d "Create worktree + tmux window + launch claude"
complete -f -c dev -n "__fish_seen_subcommand_from worktree" -a remove -d "Remove worktree, branch, and tmux window"
complete -f -c dev -n "__fish_seen_subcommand_from worktree" -a list -d "List all worktrees in the current repo"

# After 'worktree new', complete with existing worktree names
complete -f -c dev -n "__fish_seen_subcommand_from worktree; and __fish_seen_subcommand_from new" -a "(__fish_dev_worktree_names)" -d "worktree name"

# After 'worktree remove', complete with existing worktree names
complete -f -c dev -n "__fish_seen_subcommand_from worktree; and __fish_seen_subcommand_from remove" -a "(__fish_dev_worktree_names)" -d "worktree name"

function __fish_dev_worktree_names
    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null)
    if test -n "$repo_root"
        git worktree list 2>/dev/null | string match -rg '/\.worktrees/(\S+)'
    end
end
