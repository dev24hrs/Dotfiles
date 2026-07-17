# Completions for dev — git worktree management (current repo only)
complete -f -c dev

# Top-level subcommands
complete -f -c dev -n __fish_use_subcommand -a wt -d "Manage git worktrees"
complete -f -c dev -n __fish_use_subcommand -a layout -d "Create tmux session with standard project layout"

# After 'layout', complete with directory paths
complete -c dev -n "__fish_seen_subcommand_from layout" -a "(__fish_complete_directories)" -d "project path"

# After 'wt', complete with worktree subcommands
complete -f -c dev -n "__fish_seen_subcommand_from wt" -a new -d "Create worktree + tmux window + launch claude"
complete -f -c dev -n "__fish_seen_subcommand_from wt" -a remove -d "Remove worktree, branch, and tmux window"
complete -f -c dev -n "__fish_seen_subcommand_from wt" -a list -d "List all worktrees in the current repo"
complete -f -c dev -n "__fish_seen_subcommand_from wt" -a merge -d "Squash + rebase + fast-forward into target"
complete -f -c dev -n "__fish_seen_subcommand_from wt" -a clean -d "Prune stale worktree metadata"

# After 'wt new', complete with existing worktree names
complete -f -c dev -n "__fish_seen_subcommand_from wt; and __fish_seen_subcommand_from new" -a "(__fish_dev_worktree_names)" -d "worktree name"

# After 'wt remove', complete with existing worktree names
complete -f -c dev -n "__fish_seen_subcommand_from wt; and __fish_seen_subcommand_from remove" -a "(__fish_dev_worktree_names)" -d "worktree name"

# After 'wt merge', complete with existing worktree names
complete -f -c dev -n "__fish_seen_subcommand_from wt; and __fish_seen_subcommand_from merge" -a "(__fish_dev_worktree_names)" -d "worktree name"

function __fish_dev_worktree_names
    set -l git_common (git rev-parse --git-common-dir 2>/dev/null)
    if test -n "$git_common"
        git worktree list 2>/dev/null | string match -rg '/\.worktrees/(\S+)'
    end
end
