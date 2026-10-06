# dev.fish
# dev tmux [session-name] — 新建(或进入) tmux session, 单窗口 "dev", 左右 2 pane。
#
#   无参  : session 名 = <repo>-<branch>(branch 经 sanitize, 规则与 worktrunk
#           {{ branch | sanitize }} 对齐), 与 wt [post-switch] hook 建的 session 同名共用
#   1 参数: 以该参数作为 session 名
#
# 同名 session 已存在时不重建, 直接进入。
# 分割 pane 按 pane id 定位(-P -F '#{pane_id}'), 不写死 index:
# tmux.conf 设了 base-index/pane-base-index = 1, 索引不从 0 开始。

function dev --description 'dev 子命令入口 (目前仅 tmux)'
    if test (count $argv) -lt 1
        echo "Usage: dev tmux [session-name]"
        return 1
    end

    switch $argv[1]
        case tmux
            __dev_tmux $argv[2..-1]
        case '*'
            echo "Unknown subcommand: $argv[1]"
            echo "Usage: dev tmux [session-name]"
            return 1
    end
end

function __dev_tmux --description '新建/进入左右 2-pane 的 tmux dev session'
    if test (count $argv) -gt 1
        echo "Usage: dev tmux [session-name]"
        return 1
    end

    set -l work_dir (git rev-parse --show-toplevel 2>/dev/null)
    set -l session_name $argv[1]

    if test -z "$session_name"
        set -l git_common (git rev-parse --git-common-dir 2>/dev/null)
        if test -z "$git_common"; or test -z "$work_dir"
            echo "Error: not inside a git repository — name the session explicitly: dev tmux <session-name>"
            return 1
        end
        # --git-common-dir 在 linked worktree 内也指向主仓库的 .git,
        # 所以 repo 名始终是主仓库目录名(等同 wt 的 {{ repo }})
        set -l repo_name (path basename (path dirname (realpath "$git_common")))
        set -l branch (git branch --show-current 2>/dev/null)
        if test -z "$branch"
            set branch (git rev-parse --short HEAD 2>/dev/null) # detached HEAD 兜底
        end
        if test -z "$branch"
            echo "Error: cannot determine branch (empty repository?)"
            return 1
        end
        set session_name "$repo_name-$branch"
    end

    # 不在 repo 内(仅显式命名会到这)时用当前目录
    if test -z "$work_dir"
        set work_dir $PWD
    end

    set session_name (__dev_sanitize_session_name "$session_name")
    if test -z "$session_name"
        echo "Error: session name is empty after sanitizing"
        return 1
    end

    # 已存在则复用, 不重建布局
    if not tmux has-session -t "$session_name" 2>/dev/null
        # 捕获初始 pane 的 id; 之后 split/select 全部按 pane id 定位
        set -l left (tmux new-session -d -s "$session_name" -n dev -c "$work_dir" -P -F '#{pane_id}')
        or begin
            echo "Error: failed to create tmux session '$session_name'"
            return 1
        end
        tmux split-window -h -t "$left" -c "$work_dir"
        or begin
            echo "Error: failed to split pane (pane $left)"
            return 1
        end
        tmux select-pane -t "$left"
    end

    if set -q TMUX
        tmux switch-client -t "$session_name"
    else
        tmux attach-session -t "$session_name"
    end
end

# __dev_sanitize_session_name — session 名清洗, 与 worktrunk {{ branch | sanitize }} 对齐:
#   / 和 \ → -   wt 的 sanitize 规则; 保证同一 worktree 与 wt hook 建的 session 完全同名
#   :      → -   实测: 含 : 的 session 虽能创建, 但 -t 按 session:window 解析,
#                has-session/attach 等全部定位失败("can't find session: a")
#   空白   → -   交互手感; git 分支名不含空白, 不影响与 wt 的一致性
# 其余字符(中文、.、_、-、+ 等)保留: 实测可正常创建且可被 -t 定位
function __dev_sanitize_session_name --description 'sanitize tmux session name'
    set -l name $argv[1]
    set name (string replace -a '/' '-' -- "$name")
    set name (string replace -a '\\' '-' -- "$name")
    set name (string replace -a ':' '-' -- "$name")
    set name (string replace -r -a '\s' '-' -- "$name")
    echo $name
end
