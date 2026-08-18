# dev.fish
# Git worktree & tmux session management:
#   dev wt new    <name>               create worktree + dedicated tmux session
#   dev wt remove <name>               remove worktree, branch, and tmux session (current repo only)
#   dev wt list                        list all worktrees in the current repo
#   dev wt merge  <name> [target] [opts]  squash + rebase + fast-forward (local-only)
#       --no-squash  skip squash, rebase & ff each commit
#       --push       push target to remote after merge
#       --no-remove  keep worktree + branch after merge
#   dev wt clean                         prune stale worktree metadata (orphaned dirs)
#   dev layout                              create tmux session with standard project layout

# Routes to worktree subcommands (new/remove/list/merge/clean) or layout.
# Usage: dev wt new|remove|merge <name> | dev wt list|clean | dev layout
function dev --description 'manage worktrees & sessions'
    if test (count $argv) -lt 1
        echo "Usage: dev wt new|remove|merge <name> | dev wt list|clean | dev layout"
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
            if test (count $argv) -gt 1
                echo "Usage: dev layout"
                return 1
            end
            __dev_layout
        case '*'
            echo "Unknown subcommand: $subcmd"
            echo "Usage: dev wt new|remove|merge <name> | dev wt list|clean | dev layout"
            return 1
    end
end

# __dev_tmux_safe_name — sanitize names used as tmux session/window targets.
function __dev_tmux_safe_name --description 'sanitize a tmux name'
    set -l value $argv[1]
    set value (string replace -a '/' '-' -- "$value")
    set value (string replace -a ':' '-' -- "$value")
    set value (string replace -r -a '[^A-Za-z0-9_.-]' '-' -- "$value")
    echo $value
end

# __dev_tmux_session_name — derive a stable session name for a repo/worktree.
# The main worktree uses the repository name. Linked worktrees use
# <repo>-<branch>.
function __dev_tmux_session_name --description 'derive tmux session name'
    set -l repo_root $argv[1]
    set -l work_dir $argv[2]
    set -l branch $argv[3]
    set -l repo_name (path basename "$repo_root")

    if test "$work_dir" = "$repo_root"
        echo (__dev_tmux_safe_name "$repo_name")
        return 0
    end

    if test -z "$branch"
        set branch (git -C "$work_dir" branch --show-current 2>/dev/null)
    end
    if test -z "$branch"
        set branch (path basename "$work_dir")
    end

    echo (__dev_tmux_safe_name "$repo_name-$branch")
end

# __dev_worktree_new — create a worktree + dedicated tmux session
# Steps:
#   1. Validate branch name, locate repo root
#   2. Ensure .worktrees/ is in .gitignore (append if missing)
#   3. Create worktree: reuse existing branch, or git worktree add -b
#   4. Open a dedicated tmux session using the standard project layout.
function __dev_worktree_new --description 'create worktree + dedicated tmux session'
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
        echo "Worktree already exists: $dev_dir, opening session"
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

    __dev_create_layout $repo_root $dev_dir
end

# __dev_worktree_remove — clean up a worktree and its tmux session (current repo only)
# Steps:
#   1. cd to repo root (avoid "directory busy" when running from inside the worktree)
#   2. Remove worktree, then delete branch (sequential — branch -D fails while checked out)
#   3. Kill tmux session last (doing this last ensures the cleanup steps above actually run)
function __dev_worktree_remove --description 'remove worktree + branch + tmux session'
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
    set -l session_name (__dev_tmux_session_name $repo_root $dev_dir $name)

    # Step 1: cd out of the worktree so the OS doesn't block removal.
    # Critical when running this command from inside the worktree's own tmux window.
    builtin cd "$repo_root"

    # Step 2: Clean up git state BEFORE killing the session.
    # If kill-session ran first from inside the target session, SIGHUP could
    # terminate this script before it reaches the git commands.
    if test -d $dev_dir
        git worktree remove $dev_dir --force
        or begin
            echo "Error: failed to remove worktree at $dev_dir"
            return 1
        end
    end
    git branch -D $name 2>/dev/null

    # Step 3: Kill the worktree's dedicated session last (if we're inside it,
    # this ends the script).
    if tmux has-session -t $session_name 2>/dev/null
        tmux kill-session -t $session_name 2>/dev/null
    end

    echo "Cleaned up: worktree, branch $name, and tmux session $session_name"
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
        echo "✓ Merge complete. Clean up with: dev wt remove $name"
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

# __dev_create_layout — create a standard layout for a specific worktree.
# Window layout:
#   [code]  claude | nvim  (vertical 50/50)
#   [git]   lazygit
# After creation: inside tmux → switch-client, outside tmux → attach-session.
function __dev_create_layout --description 'create tmux layout for repo/worktree'
    set -l repo_root $argv[1]
    set -l work_dir $argv[2]
    set -l branch (git -C "$work_dir" branch --show-current 2>/dev/null)
    set -l session_name (__dev_tmux_session_name $repo_root $work_dir $branch)

    # Each worktree owns its own session. Reuse an existing session instead
    # of creating duplicate windows/layouts.
    if tmux has-session -t $session_name 2>/dev/null
        if set -q TMUX
            tmux switch-client -t $session_name
        else
            tmux attach-session -t $session_name
        end
        return 0
    end

    # Window 1: code — vertical 50/50 (claude | nvim)
    tmux new-session -d -s $session_name -n code -c $work_dir "claude; exec fish"
    or return 1
    tmux split-window -h -t $session_name:code -c $work_dir

    # Window 2: git — lazygit
    tmux new-window -t $session_name -n git -c $work_dir

    # Focus code window (defaults to pane 0 = claude)
    tmux select-window -t $session_name:code
    tmux select-pane -L

    if set -q TMUX
        tmux switch-client -t $session_name
    else
        tmux attach-session -t $session_name
    end
end

# __dev_layout — create the standard layout for the main repository.
# This public command intentionally accepts no path argument. It always
# resolves the main repository root from the directory where it is invoked.
function __dev_layout --description 'create tmux session with standard project layout'
    if test (count $argv) -gt 0
        echo "Usage: dev layout"
        return 1
    end

    set -l git_common (git rev-parse --git-common-dir 2>/dev/null)
    if test -z "$git_common"
        echo "Error: not a git repository"
        return 1
    end
    set -l repo_root (path dirname (realpath "$git_common"))

    __dev_create_layout $repo_root $repo_root
end
