# 禁用默认的文件补全
complete -c proxy -f

# 开启代理的选项
complete -c proxy -n __fish_use_subcommand -a "on " -d 开启代理

# 关闭代理的选项
complete -c proxy -n __fish_use_subcommand -a "off " -d 关闭代理
