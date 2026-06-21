# wt.fish
# Git worktree subcommand management:
#   wt new <name>    create worktree + tmux window + launch claude
#   wt rm  <name>    remove worktree, branch, and tmux window
#   wt list          list all worktrees in the current repo

function wt --description 'manage git worktrees: wt new|rm|list <name>'
    if test (count $argv) -lt 1
        echo "Usage: wt new <name> | wt rm <name> | wt list"
        return 1
    end

    set -l subcmd $argv[1]
    set -l name $argv[2]

    switch $subcmd
        case new
            __wt_new $name
        case remove
            __wt_remove $name
        case list
            __wt_list
        case '*'
            echo "Unknown subcommand: $subcmd"
            echo "Usage: wt new <name> | wt rm <name> | wt list"
            return 1
    end
end

function __wt_new --description 'create worktree + tmux window + claude'
    set -l name $argv[1]
    if test -z "$name"
        echo "Usage: wt new <name>"
        return 1
    end

    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$repo_root"
        echo "Error: not a git repository"
        return 1
    end

    # Ensure .claude/worktrees/ is in .gitignore so the main repo doesn't
    # show untracked files after the first worktree is created.
    set -l gitignore "$repo_root/.gitignore"
    if not grep -qx '.claude/worktrees/' $gitignore 2>/dev/null
        echo '.claude/worktrees/' >>$gitignore
        echo "Added to .gitignore: .claude/worktrees/"
    end

    set -l wt_dir "$repo_root/.claude/worktrees/$name"

    if test -d $wt_dir
        echo "Worktree already exists: $wt_dir, opening window"
    else if git show-ref --verify --quiet "refs/heads/$name"
        # Branch already exists (e.g. worktree was removed but branch kept),
        # reuse it instead of creating a new one.
        git worktree add $wt_dir $name
        or return 1
    else
        # git worktree add creates missing parent directories automatically,
        # so no need to mkdir first — even if .claude/ doesn't exist yet.
        git worktree add $wt_dir -b $name
        or return 1
    end

    tmux new-window -n $name -c $wt_dir "claude; exec fish"

    echo "Launched claude in tmux window '$name' (worktree: $wt_dir, branch: $name)"
end

function __wt_remove --description 'remove worktree + branch + tmux window'
    set -l name $argv[1]
    if test -z "$name"
        echo "Usage: wt rm <name>"
        return 1
    end

    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$repo_root"
        echo "Error: not a git repository"
        return 1
    end

    set -l wt_dir "$repo_root/.claude/worktrees/$name"

    if test -d $wt_dir
        git worktree remove $wt_dir --force
    else
        echo "Worktree directory not found: $wt_dir (skipping, cleaning up branch/window)"
    end

    git branch -D $name 2>/dev/null

    if tmux list-windows -F '#{window_name}' 2>/dev/null | grep -qx $name
        tmux send-keys -t $name C-c # gracefully exit claude
        sleep 0.3
        tmux kill-window -t $name
    end

    echo "Cleaned up: worktree directory, branch $name, exited claude, tmux window $name"
end

function __wt_list --description 'list active worktrees in this repo'
    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$repo_root"
        echo "Error: not a git repository"
        return 1
    end

    git worktree list | grep "$repo_root/.claude/worktrees/"
    or echo "No active worktrees"
end
