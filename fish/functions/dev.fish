# dev.fish
# Git worktree & tmux session management:
#   dev worktree new    <name>    create worktree in current repo + tmux window + claude & neovim
#   dev worktree remove <name>    remove worktree, branch, and tmux window (current repo only)
#   dev worktree list             list all worktrees in the current repo
#   dev layout          [path]    create tmux session with standard project layout

# dev — top-level dispatcher
# Routes to worktree subcommands (new/remove/list) or layout.
# Usage: dev worktree new|remove|list [name] | dev layout [path]
function dev --description 'manage worktrees & sessions'
    if test (count $argv) -lt 1
        echo "Usage: dev worktree new|remove|list <name> | dev layout [path]"
        return 1
    end

    set -l subcmd $argv[1]

    switch $subcmd
        case worktree
            set -l action $argv[2]
            set -l name $argv[3]
            switch $action
                case new
                    __dev_worktree_new $name
                case remove rm
                    __dev_worktree_remove $name
                case list
                    __dev_worktree_list
                case '*'
                    echo "Unknown: dev worktree $action"
                    echo "Usage: dev worktree new <name> | dev worktree remove <name> | dev worktree list"
                    return 1
            end
        case layout
            __dev_layout $argv[2]
        case '*'
            echo "Unknown subcommand: $subcmd"
            echo "Usage: dev worktree new|remove|list <name> | dev layout [path]"
            return 1
    end
end

# __dev_worktree_new — create a worktree + tmux window in the current repo
# Steps:
#   1. Validate branch name, locate repo root
#   2. Ensure .worktrees/ is in .gitignore (append if missing)
#   3. Create worktree: reuse existing branch, or git worktree add -b
#   4. Open tmux window (claude | nvim split) in the repo's session:
#      - Session exists → new-window in that session
#      - No session, inside tmux → new-session -d + switch-client
#      - No session, outside tmux → new-session (attach directly)
function __dev_worktree_new --description 'create worktree + tmux window + claude'
    set -l name $argv[1]
    if test -z "$name"
        echo "Usage: dev worktree new <name>"
        return 1
    end

    if not git check-ref-format --branch "$name" 2>/dev/null
        echo "Error: '$name' is not a valid branch name"
        return 1
    end

    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$repo_root"
        echo "Error: not a git repository"
        return 1
    end

    # Ensure .worktrees/ is in .gitignore so the main repo doesn't
    # show untracked files after the first worktree is created.
    set -l gitignore "$repo_root/.gitignore"
    if not grep -qE '^\.worktrees/?$' $gitignore 2>/dev/null
        # printf (not echo) ensures the entry starts on its own line even
        # when .gitignore is missing a trailing newline.
        printf '\n.worktrees/\n' >>$gitignore
        echo "Added to .gitignore: .worktrees/"
    end

    set -l dev_dir "$repo_root/.worktrees/$name"

    if test -d $dev_dir
        echo "Worktree already exists: $dev_dir, opening window"
    else if git show-ref --verify --quiet "refs/heads/$name"
        # Branch already exists (e.g. worktree was removed but branch kept),
        # reuse it instead of creating a new one.
        git worktree add $dev_dir $name
        or return 1
    else
        # git worktree add creates .worktrees/ automatically; no mkdir needed.
        git worktree add $dev_dir -b $name
        or return 1
    end

    set -l session_name (path basename $repo_root)
    if tmux has-session -t $session_name 2>/dev/null
        tmux new-window -t $session_name -n $name -c $dev_dir "claude; exec fish"
        tmux split-window -h -t $session_name:$name -c $dev_dir "nvim; exec fish"
        tmux select-pane -L
        echo "Launched claude in tmux window '$name' (session: $session_name, worktree: $dev_dir)"
    else if set -q TMUX
        tmux new-session -d -s $session_name -n $name -c $dev_dir "claude; exec fish"
        tmux split-window -h -t $session_name:$name -c $dev_dir "nvim; exec fish"
        tmux select-pane -L
        tmux switch-client -t $session_name
        echo "Launched claude in new session '$session_name' (worktree: $dev_dir)"
    else
        tmux new-session -s $session_name -n $name -c $dev_dir "claude; exec fish"
        tmux split-window -h -t $session_name:$name -c $dev_dir "nvim; exec fish"
        tmux select-pane -L
    end
end

# __dev_worktree_remove — clean up a worktree and its tmux window (current repo only)
# Steps:
#   1. Send C-c to the tmux window (best-effort graceful), then kill-window immediately
#   2. git worktree remove --force and git branch -D run in parallel via &
#   3. wait for both background jobs
function __dev_worktree_remove --description 'remove worktree + branch + tmux window'
    set -l name $argv[1]
    if test -z "$name"
        echo "Usage: dev worktree remove <name>"
        return 1
    end

    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$repo_root"
        echo "Error: not a git repository"
        return 1
    end

    set -l dev_dir "$repo_root/.worktrees/$name"
    set -l session_name (path basename $repo_root)

    # Kill tmux window (best-effort graceful then immediate kill)
    if tmux list-windows -t $session_name -F '#{window_name}' 2>/dev/null | string match --entire --quiet -- $name
        tmux send-keys -t $session_name:$name C-c 2>/dev/null
        tmux kill-window -t $session_name:$name 2>/dev/null
    end

    # Remove worktree and branch in parallel with tmux cleanup
    if test -d $dev_dir
        git worktree remove $dev_dir --force &
    end

    git branch -D $name 2>/dev/null &
    wait

    echo "Cleaned up: worktree, branch $name, and tmux window"
end

# __dev_worktree_list — list worktrees under .worktrees/ in the current repo
# Runs git worktree list and filters to repo_root/.worktrees/.
function __dev_worktree_list --description 'list active worktrees in this repo'
    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$repo_root"
        echo "Error: not a git repository"
        return 1
    end

    git worktree list | grep "$repo_root/.worktrees/"
    or echo "No active worktrees"
end

# __dev_layout — create a tmux session with a standard 4-window project layout
# Accepts an optional path argument (defaults to PWD).
# Window layout:
#   [code]  claude | nvim  (vertical 50/50)
#   [git]   lazygit
#   [chore] empty | empty  (vertical 50/50)
#   [log]   empty
# After creation: inside tmux → switch-client, outside tmux → attach-session.
function __dev_layout --description 'create tmux session with standard project layout'
    set -l target $argv[1]

    if test -n "$target"
        set target (realpath "$target" 2>/dev/null)
        or begin
            echo "Error: '$argv[1]' is not a valid path"
            return 1
        end
    else
        set target $PWD
    end

    set -l repo_root (git -C "$target" rev-parse --show-toplevel 2>/dev/null)
    if test -z "$repo_root"
        echo "Error: not a git repository"
        return 1
    end

    set -l session_name (path basename $repo_root)
    set -l work_dir $repo_root

    # Window 1: code — vertical 50/50 (claude | nvim)
    tmux new-session -d -s $session_name -n code -c $work_dir "claude; exec fish"
    or return 1
    tmux split-window -h -t $session_name:code -c $work_dir "nvim; exec fish"

    # Window 2: git — lazygit
    tmux new-window -t $session_name -n git -c $work_dir "lazygit; exec fish"

    # Window 3: chore — vertical 50/50, empty
    tmux new-window -t $session_name -n chore -c $work_dir
    tmux split-window -h -t $session_name:chore -c $work_dir

    # Window 4: log — empty
    tmux new-window -t $session_name -n log -c $work_dir

    # Focus code window (defaults to pane 0 = claude)
    tmux select-window -t $session_name:code
    tmux select-pane -L

    if set -q TMUX
        tmux switch-client -t $session_name
    else
        tmux attach-session -t $session_name
    end
end
