set -g LAST_PWD_FILE "$HOME/.fish_last_pwd"

# 定义保存函数
function __save_last_pwd --on-variable PWD
    if status is-interactive
        echo $PWD >$LAST_PWD_FILE
    end
end

if status is-interactive
    if not set -q __fish_last_pwd_initialized
        # Skip restore inside tmux — the window/pane creator sets the directory
        # explicitly via -c, and restoring would overwrite it.
        if not set -q TMUX; and test -f $LAST_PWD_FILE
            set -l last_dir (cat $LAST_PWD_FILE)
            if test -d "$last_dir"
                cd "$last_dir"
            end
        end
        # 设置全局变量标记，防止同个会话中 source 时重复触发
        set -g __fish_last_pwd_initialized 1
    end
end
