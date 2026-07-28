# 禁用默认的文件补全（除非子命令需要）
complete -c tool -f

complete -c tool -n __fish_use_subcommand -a "nh " -d "使用 nohup 后台运行命令"
# 为 nh 子命令开启后续的命令/文件补全
complete -c tool -n "__fish_seen_subcommand_from nh" -a "(__fish_complete_subcommand)"

complete -c tool -n __fish_use_subcommand -a "ch " -d "查询 cheat.sh 备忘录"

complete -c tool -n __fish_use_subcommand -a "dsclean " -d "清除当前目录下的 .DS_Store 文件"
