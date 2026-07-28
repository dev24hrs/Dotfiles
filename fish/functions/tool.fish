function tool --description '通用工具箱 (包含 nh, ch, dsclean)'
    # 如果没有参数，显示帮助信息
    if test (count $argv) -eq 0
        set argv help
    end

    switch $argv[1]
        case nh
            # 使用 $argv[2..-1] 获取除子命令外的所有剩余参数
            nohup $argv[2..-1] &>/dev/null &

        case ch
            # 使用 $argv[2] 作为查询关键字
            curl cheat.sh/$argv[2]

        case dsclean
            find . -name ".DS_Store" -depth -delete
            echo (set_color green)"✨ .DS_Store files have been purged!"(set_color normal)

        case help '*'
            echo (set_color yellow)"可用工具子命令:"(set_color normal)
            echo "tool nh <cmd>     - 使用 nohup 后台运行命令"
            echo "tool ch <query>   - 查询 cheat.sh 备忘录"
            echo "tool dsclean      - 清除当前目录下的 .DS_Store 文件"
    end
end
