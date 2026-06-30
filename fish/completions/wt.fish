# Completions for wt — git worktree management
complete -f -c wt

complete -f -c wt -n __fish_wt_no_subcommand -a new -d "Create worktree + tmux window + launch claude"
complete -f -c wt -n __fish_wt_no_subcommand -a rm -d "Remove worktree, branch, and tmux window"
complete -f -c wt -n __fish_wt_no_subcommand -a list -d "List all worktrees in the current repo"

# After 'new' or 'rm', complete with existing worktree names (no file completion)
complete -f -c wt -n "__fish_seen_subcommand_from new rm" -a "(__fish_wt_worktree_names)" -d "worktree name"

function __fish_wt_no_subcommand
    for i in (commandline -opc)
        if contains -- $i new rm list
            return 1
        end
    end
    return 0
end

function __fish_wt_worktree_names
    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null)
    if test -n "$repo_root"
        git worktree list 2>/dev/null | sed -n 's|.*/\.claude/worktrees/\([^[:space:]]*\).*|\1|p'
    end
end
