# dev.fish
# Git worktree & tmux session management:
#   dev wt new    <name>               create worktree in current repo + tmux window (claude | empty)
#   dev wt remove <name>               remove worktree, branch, and tmux window (current repo only)
#   dev wt list                        list all worktrees in the current repo
#   dev wt merge  <name> [target] [opts]  squash + rebase + fast-forward (local-only)
#       --no-squash  skip squash, rebase & ff each commit
#       --push       push target to remote after merge
#       --no-remove  keep worktree + branch after merge
#   dev wt clean                         prune stale worktree metadata (orphaned dirs)
#   dev layout          [path]               create tmux session with standard project layout

# Routes to worktree subcommands (new/remove/list/merge/clean) or layout.
# Usage: dev wt new|remove|merge <name> | dev wt list|clean | dev layout [path]
function dev --description 'manage worktrees & sessions'
    if test (count $argv) -lt 1
        echo "Usage: dev wt new|remove|merge <name> | dev wt list|clean | dev layout [path]"
        return 1
    end

    set -l subcmd $argv[1]

    switch $subcmd
        case wt
            set -l action $argv[2]
            set -l name $argv[3]
            switch $action
                case new
                    __dev_worktree_new $name
                case remove
                    __dev_worktree_remove $name
                case list
                    __dev_worktree_list
                case merge
                    __dev_worktree_merge $name $argv[4..-1]
                case clean
                    __dev_worktree_clean
                case '*'
                    echo "Unknown: dev wt $action"
                    echo "Usage: dev wt new|remove|merge <name> | dev wt list|clean"
                    return 1
            end
        case layout
            __dev_layout $argv[2]
        case '*'
            echo "Unknown subcommand: $subcmd"
            echo "Usage: dev wt new|remove|merge <name> | dev wt list|clean | dev layout [path]"
            return 1
    end
end

# __dev_worktree_new — create a worktree + tmux window in the current repo
# Steps:
#   1. Validate branch name, locate repo root
#   2. Ensure .worktrees/ is in .gitignore (append if missing)
#   3. Create worktree: reuse existing branch, or git worktree add -b
#   4. Open tmux window (claude | empty split) in the repo's session:
#      - Session exists → new-window in that session
#      - No session, inside tmux → new-session -d + switch-client
#      - No session, outside tmux → new-session (attach directly)
function __dev_worktree_new --description 'create worktree + tmux window + claude'
    set -l name $argv[1]
    if test -z "$name"
        echo "Usage: dev wt new <name>"
        return 1
    end

    if not git check-ref-format --branch "$name" 2>/dev/null
        echo "Error: '$name' is not a valid branch name"
        return 1
    end

    # --git-common-dir always points to the main repo's .git, even inside
    # a linked worktree (where --show-toplevel would return the worktree path).
    set -l git_common (git rev-parse --git-common-dir 2>/dev/null)
    if test -z "$git_common"
        echo "Error: not a git repository"
        return 1
    end
    set -l repo_root (path dirname (realpath "$git_common"))

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
        tmux new-window -t $session_name -n $name -c $dev_dir "cd $dev_dir; claude; exec fish"
        tmux split-window -h -t $session_name:$name -c $dev_dir "cd $dev_dir; exec fish"
        echo "Launched claude in tmux window '$name' (session: $session_name, worktree: $dev_dir)"
    else if set -q TMUX
        tmux new-session -d -s $session_name -n $name -c $dev_dir "cd $dev_dir; claude; exec fish"
        tmux split-window -h -t $session_name:$name -c $dev_dir "cd $dev_dir; exec fish"
        tmux switch-client -t $session_name
        echo "Launched claude in new session '$session_name' (worktree: $dev_dir)"
    else
        tmux new-session -s $session_name -n $name -c $dev_dir "cd $dev_dir; claude; exec fish"
        tmux split-window -h -t $session_name:$name -c $dev_dir "cd $dev_dir; exec fish"
    end
end

# __dev_worktree_remove — clean up a worktree and its tmux window (current repo only)
# Steps:
#   1. cd to repo root (avoid "directory busy" when running from inside the worktree)
#   2. Remove worktree, then delete branch (sequential — branch -D fails while checked out)
#   3. Kill tmux window last (doing this last ensures the cleanup steps above actually run)
function __dev_worktree_remove --description 'remove worktree + branch + tmux window'
    set -l name $argv[1]
    if test -z "$name"
        echo "Usage: dev wt remove <name>"
        return 1
    end

    # --git-common-dir always points to the main repo's .git, even inside
    # a linked worktree (where --show-toplevel would return the worktree path).
    set -l git_common (git rev-parse --git-common-dir 2>/dev/null)
    if test -z "$git_common"
        echo "Error: not a git repository"
        return 1
    end
    set -l repo_root (path dirname (realpath "$git_common"))

    set -l dev_dir "$repo_root/.worktrees/$name"
    set -l session_name (path basename $repo_root)

    # Step 1: cd out of the worktree so the OS doesn't block removal.
    # Critical when running this command from inside the worktree's own tmux window.
    builtin cd "$repo_root"

    # Step 2: Clean up git state BEFORE killing the window.
    # If kill-window ran first from inside the target window, SIGHUP could
    # terminate this script before it reaches the git commands.
    if test -d $dev_dir
        git worktree remove $dev_dir --force
        or begin
            echo "Error: failed to remove worktree at $dev_dir"
            return 1
        end
    end
    git branch -D $name 2>/dev/null

    # Step 3: Kill tmux window last (if we're inside it, this ends the script).
    if tmux list-windows -t $session_name -F '#{window_name}' 2>/dev/null | string match --entire --quiet -- $name
        tmux kill-window -t $session_name:$name 2>/dev/null
    end

    echo "Cleaned up: worktree, branch $name, and tmux window"
end

# __dev_worktree_merge — squash, rebase, and fast-forward target (worktrunk-style, local-only)
# Steps:
#   1. Validate worktree & branch exist, detect target branch
#   2. Block on uncommitted changes in the worktree
#   3. Create safety backup: git branch wt-backup/<name> <name>
#   4. Squash (default): soft-reset to merge-base, commit all changes as one
#   5. Rebase onto target (conflict → abort with recovery instructions)
#   6. Fast-forward target: git checkout <target> && git merge --ff-only <name>
#   7. Remove worktree & branch (default; --no-remove to keep)
#   8. Push to remote (opt-in: --push)
function __dev_worktree_merge --description 'squash + rebase + fast-forward (local-only)'
    set -l name $argv[1]
    if test -z "$name"
        echo "Usage: dev wt merge <name> [target-branch] [--no-squash] [--push] [--no-remove]"
        return 1
    end

    # Parse flags and target from remaining args
    set -l target ""
    set -l no_squash false
    set -l do_push false
    set -l no_remove false

    for arg in $argv[2..-1]
        switch $arg
            case --no-squash
                set no_squash true
            case --push
                set do_push true
            case --no-remove
                set no_remove true
            case '-*'
                echo "Unknown flag: $arg"
                return 1
            case '*'
                if test -z "$target"
                    set target $arg
                else
                    echo "Error: unexpected argument '$arg'"
                    return 1
                end
        end
    end

    # --git-common-dir always points to the main repo's .git, even inside
    # a linked worktree (where --show-toplevel would return the worktree path).
    set -l git_common (git rev-parse --git-common-dir 2>/dev/null)
    if test -z "$git_common"
        echo "Error: not a git repository"
        return 1
    end
    set -l repo_root (path dirname (realpath "$git_common"))

    set -l dev_dir "$repo_root/.worktrees/$name"

    if not test -d $dev_dir
        echo "Error: worktree '$name' not found at $dev_dir"
        return 1
    end

    if not git show-ref --verify --quiet "refs/heads/$name"
        echo "Error: branch '$name' does not exist"
        return 1
    end

    # Detect default target branch from remote HEAD
    if test -z "$target"
        set target (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|.*/||')
        if test -z "$target"
            echo "Error: could not detect default branch. Specify target explicitly."
            return 1
        end
    end

    # Block if worktree has uncommitted changes
    set -l dirty (git -C $dev_dir status --porcelain 2>/dev/null)
    if test -n "$dirty"
        echo "Error: worktree has uncommitted changes:"
        git -C $dev_dir status --short
        echo "Commit or stash them first, then retry."
        return 1
    end

    # Count commits on this branch (for display)
    set -l merge_base (git -C $dev_dir merge-base HEAD $target 2>/dev/null)
    if test -z "$merge_base"
        echo "Error: no common ancestor with '$target'"
        return 1
    end
    set -l commit_count (git -C $dev_dir rev-list --count $merge_base..HEAD 2>/dev/null)

    echo "→ Merging '$name' into '$target' ($commit_count commit(s))"

    # --- Step 1: Safety backup ---
    set -l backup_ref "wt-backup/$name"
    if git show-ref --verify --quiet "refs/heads/$backup_ref"
        git branch -D $backup_ref 2>/dev/null
    end
    git branch $backup_ref $name
    or begin
        echo "Error: failed to create backup branch '$backup_ref'"
        return 1
    end
    echo "→ Backup: $backup_ref"

    # --- Step 2: Squash (default) ---
    set -l squashed false
    if not $no_squash; and test $commit_count -gt 1
        echo "→ Squashing $commit_count commits..."
        # Build squash message from original commit subjects
        set -l squash_msg (git -C $dev_dir log --reverse --format='%s' $merge_base..HEAD | string collect)
        git -C $dev_dir reset --soft $merge_base
        or begin
            echo "Error: soft-reset failed"
            return 1
        end
        git -C $dev_dir commit -m "$squash_msg" --no-verify
        or begin
            echo "Error: squash commit failed"
            echo "To recover: git -C $dev_dir reset --soft HEAD@{1} && git -C $dev_dir commit -m 'recovery'"
            return 1
        end
        set squashed true
        echo "→ Squashed to 1 commit"
    else if not $no_squash
        echo "→ (single commit, skipping squash)"
    end

    # --- Step 3: Rebase onto target ---
    echo "→ Rebasing onto $target..."
    git -C $dev_dir rebase $target
    or begin
        echo "Rebase conflict! Aborting rebase..."
        git -C $dev_dir rebase --abort 2>/dev/null
        if $squashed
            echo "Squash was applied — resetting to backup to restore original commits..."
            git -C $dev_dir reset --hard $backup_ref 2>/dev/null
        end
        echo "Recovery: branch is back at backup '$backup_ref'"
        return 1
    end

    # --- Step 4: Fast-forward target ---
    # cd to main repo — git checkout would fail from a linked worktree
    # if $target is already checked out in the main worktree.
    cd "$repo_root"
    set -l prev_branch (git branch --show-current)
    echo "→ Fast-forwarding $target to $name..."
    git checkout $target
    or begin
        echo "Error: checkout $target failed"
        return 1
    end
    git merge --ff-only $name
    or begin
        echo "Error: fast-forward failed (unexpected after rebase)"
        echo "This shouldn't happen — check git log for divergence."
        git checkout $prev_branch 2>/dev/null
        return 1
    end

    # --- Step 5: Push (opt-in) ---
    if $do_push
        echo "→ Pushing $target..."
        git push origin $target
        or begin
            echo "Error: push failed. Push manually when ready."
            return 1
        end
    end

    # --- Step 6: Cleanup ---
    if not $no_remove
        echo "→ Removing worktree, branch, and backup..."
        __dev_worktree_remove $name
        git branch -D $backup_ref 2>/dev/null
    else
        echo "→ Deleting backup branch '$backup_ref'..."
        git branch -D $backup_ref 2>/dev/null
        echo "✓ Merge complete. Clean up with: dev worktree remove $name"
    end

    if test -n "$prev_branch"; and test "$prev_branch" != "$target"
        echo "  (you are now on '$target'; was on '$prev_branch')"
    end
end

# __dev_worktree_list — list worktrees under .worktrees/ in the current repo
function __dev_worktree_list --description 'list active worktrees in this repo'
    set -l git_common (git rev-parse --git-common-dir 2>/dev/null)
    if test -z "$git_common"
        echo "Error: not a git repository"
        return 1
    end
    set -l repo_root (path dirname (realpath "$git_common"))

    git worktree list | grep "$repo_root/.worktrees/"
    or echo "No active worktrees"
end

# __dev_worktree_clean — prune stale worktree metadata
# Runs `git worktree prune` to remove entries for worktrees whose directories
# no longer exist (e.g. manually deleted or lost after a disk cleanup).
function __dev_worktree_clean --description 'prune stale worktree metadata'
    set -l git_common (git rev-parse --git-common-dir 2>/dev/null)
    if test -z "$git_common"
        echo "Error: not a git repository"
        return 1
    end
    # repo_root not used by prune, but validated for "in a repo" check above.

    set -l pruned (git worktree prune --verbose 2>&1)
    or begin
        echo "Error: prune failed"
        return 1
    end
    if test -n "$pruned"
        printf '%s\n' $pruned
    else
        echo "No stale worktrees to prune"
    end
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

    set -l git_common (git -C "$target" rev-parse --git-common-dir 2>/dev/null)
    if test -z "$git_common"
        echo "Error: not a git repository"
        return 1
    end
    set -l repo_root (path dirname (realpath "$git_common"))

    set -l session_name (path basename $repo_root)
    set -l work_dir $repo_root

    # Window 1: code — vertical 50/50 (claude | nvim)
    tmux new-session -d -s $session_name -n code -c $work_dir "claude; exec fish"
    or return 1
    tmux split-window -h -t $session_name:code -c $work_dir

    # Window 2: git — lazygit
    tmux new-window -t $session_name -n git -c $work_dir "lazygit; exec fish"

    # Window 3: chore — vertical 50/50, empty
    tmux new-window -t $session_name -n chore -c $work_dir
    tmux split-window -h -t $session_name:chore -c $work_dir

    # Focus code window (defaults to pane 0 = claude)
    tmux select-window -t $session_name:code
    tmux select-pane -L

    if set -q TMUX
        tmux switch-client -t $session_name
    else
        tmux attach-session -t $session_name
    end
end
